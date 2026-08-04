import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService extends ChangeNotifier {
  static String get serverUrl => AppConfig.socketUrl;

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  io.Socket? get socket => _socket;

  void initSocket(String userId) {
    if (_socket != null && _isConnected) return;

    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket?.onConnect((_) {
      _isConnected = true;
      notifyListeners();
      _socket?.emit("join-user-chat", {"userId": userId});
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
    });
  }

  void joinRoom(String roomCode, Map<String, dynamic> user) {
    _socket?.emit("join-room", {
      "roomCode": roomCode,
      "user": user,
    });
  }

  void leaveRoom(String roomCode, Map<String, dynamic> user) {
    _socket?.emit("leave-room", {
      "roomCode": roomCode,
      "user": user,
    });
  }

  void sendMessage(Map<String, dynamic> messageData) {
    _socket?.emit("send-message", messageData);
  }

  void startRoomQuiz(String roomCode, String topic) {
    _socket?.emit("start-room-quiz", {
      "roomCode": roomCode,
      "topic": topic,
    });
  }

  void submitQuizAnswer(String roomCode, String userId, int questionIndex, int selectedOption) {
    _socket?.emit("submit-quiz-answer", {
      "roomCode": roomCode,
      "userId": userId,
      "questionIndex": questionIndex,
      "selectedOption": selectedOption,
    });
  }

  void requestAIReferee(String roomCode, String topic, String explanationA, String userA, String explanationB, String userB) {
    _socket?.emit("request-ai-referee", {
      "roomCode": roomCode,
      "topic": topic,
      "explanationA": explanationA,
      "userA": userA,
      "explanationB": explanationB,
      "userB": userB,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }
}
