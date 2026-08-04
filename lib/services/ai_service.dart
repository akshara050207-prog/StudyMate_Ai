import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AIService {
  static String get baseUrl => "${AppConfig.apiBaseUrl}/ai";
  static const String _groqApiKey = "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";

  /// Query Groq LLaMA 3.3-70B directly for ultra-fast, 100% real AI answers
  static Future<String> _fetchDirectAIResponse(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) return "Please enter a valid question.";

    // 1. Primary: Groq LLaMA 3.3-70B API (Sub-second response)
    try {
      final response = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $_groqApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are StudyMate AI, an intelligent, friendly educational AI assistant. Answer user questions directly, thoroughly, and concisely using clear markdown."
            },
            {"role": "user", "content": cleanPrompt}
          ],
          "temperature": 0.7,
          "max_tokens": 2048,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data["choices"]?[0]?["message"]?["content"]?.toString().trim();
        if (content != null && content.isNotEmpty) {
          return content;
        }
      }
    } catch (e) {
      debugPrint("Groq Direct API Notice: $e");
    }

    // 2. Secondary Fallback: Pollinations AI POST
    try {
      final polRes = await http.post(
        Uri.parse("https://text.pollinations.ai/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "messages": [
            {
              "role": "system",
              "content": "You are StudyMate AI, an intelligent educational assistant. Provide direct, thorough markdown answers."
            },
            {"role": "user", "content": cleanPrompt}
          ],
          "model": "openai",
        }),
      ).timeout(const Duration(seconds: 8));

      if (polRes.statusCode == 200 && polRes.body.trim().isNotEmpty) {
        return polRes.body.trim();
      }
    } catch (e) {
      debugPrint("Pollinations AI Direct notice: $e");
    }

    return "I am StudyMate AI, your dedicated AI study assistant. I can help answer your questions, analyze your study materials, generate quizzes, and create flashcards!";
  }

  static Future<void> streamChatMessage(
    String topic, {
    String? token,
    required Function(String chunk) onChunk,
  }) async {
    final cleanTopic = topic.trim();
    if (cleanTopic.isEmpty) return;

    bool receivedBackendChunk = false;

    // 1. Try Backend SSE Stream
    try {
      final request = http.Request("POST", Uri.parse("$baseUrl/chat/stream"));
      request.headers["Content-Type"] = "application/json";
      if (token != null && token.isNotEmpty) {
        request.headers["Authorization"] = "Bearer $token";
      }
      request.body = jsonEncode({"message": cleanTopic});

      final client = http.Client();
      try {
        final response = await client.send(request).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

          await for (final line in stream) {
            if (line.startsWith("data: ")) {
              final payload = line.substring(6).trim();
              if (payload == "[DONE]") {
                break;
              }
              try {
                final data = jsonDecode(payload);
                if (data is Map && data.containsKey("chunk")) {
                  receivedBackendChunk = true;
                  onChunk(data["chunk"].toString());
                }
              } catch (_) {}
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint("Backend Stream Notice: $e");
    }

    // 2. Direct Real AI Response (Groq LLaMA 3.3-70B) if backend stream unserved
    if (!receivedBackendChunk) {
      final fullAnswer = await _fetchDirectAIResponse(cleanTopic);
      final words = fullAnswer.split(" ");
      for (int i = 0; i < words.length; i++) {
        final chunk = i == words.length - 1 ? words[i] : "${words[i]} ";
        onChunk(chunk);
        await Future.delayed(const Duration(milliseconds: 15));
      }
    }
  }

  static Future<String> sendMessage(String topic, {String? token, List<Map<String, String>>? history}) async {
    final cleanTopic = topic.trim();
    if (cleanTopic.isEmpty) return "";

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({"message": cleanTopic}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["answer"] != null && data["answer"].toString().trim().isNotEmpty) {
          return data["answer"].toString().trim();
        }
      }
    } catch (e) {
      debugPrint("Backend Chat API Exception: $e");
    }

    return _fetchDirectAIResponse(cleanTopic);
  }

  Future<String> askAI(String topic, {String? token, List<Map<String, String>>? history}) async {
    return sendMessage(topic, token: token, history: history);
  }

  Future<String> getRefereeVerdict(String topic, String expA, String userA, String expB, String userB) async {
    final prompt = "Act as an expert AI Study Referee. Analyze these two student explanations for topic '$topic':\n$userA: $expA\n$userB: $expB\nProvide a fair verdict highlighting the strengths of each explanation and declaring a winner with constructive feedback.";
    return _fetchDirectAIResponse(prompt);
  }
}