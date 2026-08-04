import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class UploadService {
  static String get baseUrl => AppConfig.serverUrl;

  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/api/upload"),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        filePath,
      ),
    );

    var response = await request.send();
    var body = await response.stream.bytesToString();

    return jsonDecode(body);
  }
}