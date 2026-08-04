import 'package:flutter/foundation.dart';

class AppConfig {
  static String? customServerHost;

  static String get serverUrl {
    if (customServerHost != null && customServerHost!.trim().isNotEmpty) {
      return customServerHost!.trim();
    }
    if (kIsWeb) {
      return "http://localhost:3000";
    }
    return "http://10.0.2.2:3000";
  }

  static String get apiBaseUrl => "$serverUrl/api";
  static String get socketUrl => serverUrl;
}
