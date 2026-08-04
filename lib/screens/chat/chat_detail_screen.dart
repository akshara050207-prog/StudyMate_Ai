import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ChatDetailScreen extends StatefulWidget {
  final UserModel friend;

  const ChatDetailScreen({super.key, required this.friend});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final List<MessageModel> _messages = [];
  bool _isFriendTyping = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = Provider.of<SocketService>(context, listen: false);

      socket.socket?.on("new-message", (data) {
        if (mounted && data != null) {
          final msg = MessageModel.fromJson(data);
          if (msg.senderId == widget.friend.id || msg.receiverId == widget.friend.id) {
            setState(() {
              _messages.add(msg);
            });
          }
        }
      });

      socket.socket?.on("user-typing", (data) {
        if (mounted && data['senderId'] == widget.friend.id) {
          setState(() {
            _isFriendTyping = data['isTyping'] ?? false;
          });
        }
      });
    });
  }

  void _loadHistory() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token != null) {
      final history = await ApiService.fetchChatHistory(widget.friend.id, auth.token!);
      if (mounted && history.isNotEmpty) {
        setState(() {
          _messages.addAll(history);
        });
      }
    }

    if (_messages.isEmpty) {
      setState(() {
        _messages.addAll([
          MessageModel(
            id: "msg_1",
            senderId: widget.friend.id,
            senderName: widget.friend.name,
            senderAvatar: widget.friend.avatar,
            receiverId: "user_me",
            content: "Hey! Ready for our DBMS study session today?",
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
          MessageModel(
            id: "msg_2",
            senderId: "user_me",
            senderName: "Me",
            senderAvatar: "",
            receiverId: widget.friend.id,
            content: "Yes! Let's cover SQL Joins and Normalization quiz.",
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ]);
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final currentUser = auth.currentUser;
    final socket = Provider.of<SocketService>(context, listen: false);

    final newMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUser?.id ?? "user_me",
      senderName: currentUser?.name ?? "Me",
      senderAvatar: currentUser?.avatar ?? "",
      receiverId: widget.friend.id,
      content: text,
      isRead: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(newMsg);
      _messageController.clear();
    });

    socket.sendMessage({
      "senderId": currentUser?.id ?? "user_me",
      "senderName": currentUser?.name ?? "Me",
      "senderAvatar": currentUser?.avatar ?? "",
      "receiverId": widget.friend.id,
      "content": text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.friend.avatar.isNotEmpty
                  ? NetworkImage(widget.friend.avatar)
                  : null,
              child: widget.friend.avatar.isEmpty ? Text(widget.friend.name[0]) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friend.name, style: AppTypography.headingSmall(isDark: isDark)),
                Text(
                  _isFriendTyping ? "typing..." : "Online",
                  style: TextStyle(
                    fontSize: 12,
                    color: _isFriendTyping ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.senderId == (currentUser?.id ?? "user_me");

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMe ? AppColors.primaryGradient : null,
                      color: isMe
                          ? null
                          : (isDark ? AppColors.surfaceDark : AppColors.cardLight),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                      ),
                      border: isMe
                          ? null
                          : Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                    ),
                    child: Text(
                      msg.content,
                      style: AppTypography.bodyMedium(isDark: isDark).copyWith(
                        color: isMe ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "Type a study message...",
                      filled: true,
                      fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
