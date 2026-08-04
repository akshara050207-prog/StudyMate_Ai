import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/material_model.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Generate AI study material from raw text or uploaded PDF file
  static Future<MaterialModel?> generateStudyMaterial({
    required String token,
    String? text,
    File? pdfFile,
    String? title,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/materials/generate");
      final request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] = "Bearer $token";

      if (text != null && text.trim().isNotEmpty) {
        request.fields["text"] = text.trim();
      }
      if (title != null && title.trim().isNotEmpty) {
        request.fields["title"] = title.trim();
      }

      if (pdfFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("file", pdfFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['material'] != null) {
          return MaterialModel.fromJson(data['material']);
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? "Failed to generate material.");
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Fetch all saved study materials for logged in user
  static Future<List<MaterialModel>> fetchUserMaterials(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/materials"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data['materials'] ?? [];
        return raw.map((m) => MaterialModel.fromJson(m)).toList();
      }
    } catch (e) {
      // Return empty list on failure
    }
    return [];
  }

  /// Delete material by ID
  static Future<bool> deleteMaterial(String materialId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/materials/$materialId"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      // Ignore
    }
    return false;
  }

  /// Add portfolio project to user profile
  static Future<UserModel?> addPortfolioProject({
    required String token,
    required String title,
    required String description,
    required String link,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/profile/projects"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "description": description,
          "link": link,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user']);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  /// Delete portfolio project from user profile
  static Future<UserModel?> deletePortfolioProject({
    required String token,
    required String projectId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/profile/projects/$projectId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user']);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  /// Update user profile basic info
  static Future<UserModel?> updateProfile({
    required String token,
    String? name,
    String? bio,
    String? avatar,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> bodyMap = {};
      if (name != null) bodyMap["name"] = name;
      if (bio != null) bodyMap["bio"] = bio;
      if (avatar != null) bodyMap["avatar"] = avatar;
      if (phone != null) bodyMap["phone"] = phone;

      final response = await http.put(
        Uri.parse("$baseUrl/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user']);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  /// Chat APIs
  static Future<List<UserModel>> fetchChatUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/chat/users"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data['users'] ?? [];
        return raw.map((u) => UserModel.fromJson(u)).toList();
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  static Future<List<MessageModel>> fetchChatHistory(String friendId, String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/chat/history/$friendId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data['messages'] ?? [];
        return raw.map((m) => MessageModel.fromJson(m)).toList();
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  /// Study Room APIs
  static Future<List<RoomModel>> fetchFeaturedRooms(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rooms/featured"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data['rooms'] ?? [];
        return raw.map((r) => RoomModel.fromJson(r)).toList();
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  static Future<RoomModel?> createRoom({
    required String topic,
    required String token,
    String? title,
    String? description,
    String? subjectTag,
    bool isPublic = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rooms/create"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "topic": topic,
          "title": title ?? topic,
          "description": description ?? "",
          "subjectTag": subjectTag ?? "General",
          "isPublic": isPublic,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RoomModel.fromJson(data['room']);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  static Future<RoomModel?> joinRoom({
    String? code,
    String? roomId,
    required String token,
  }) async {
    try {
      final Map<String, dynamic> bodyMap = {};
      if (code != null) bodyMap["code"] = code;
      if (roomId != null) bodyMap["roomId"] = roomId;

      final response = await http.post(
        Uri.parse("$baseUrl/rooms/join"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RoomModel.fromJson(data['room']);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  /// Freeform AI Assistant Chat APIs
  static Future<Map<String, dynamic>?> sendAIChatMessage({
    required String message,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/ai/chat"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchAIChatHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/ai/chat/history"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data['messages'] ?? [];
        return raw.map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  static Future<bool> clearAIChatHistory(String token) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/ai/chat/history"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      // Ignore
    }
    return false;
  }
}
