import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDUg1XwHBf_l0r440PiijZ-rWNsidYUvS4',
    appId: '1:946601129058:web:d831a7926c4e1563070d3b',
    messagingSenderId: '946601129058',
    projectId: 'studymateai-83db5',
    storageBucket: 'studymateai-83db5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUg1XwHBf_l0r440PiijZ-rWNsidYUvS4',
    appId: '1:946601129058:android:d831a7926c4e1563070d3b',
    messagingSenderId: '946601129058',
    projectId: 'studymateai-83db5',
    storageBucket: 'studymateai-83db5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUg1XwHBf_l0r440PiijZ-rWNsidYUvS4',
    appId: '1:946601129058:ios:d831a7926c4e1563070d3b',
    messagingSenderId: '946601129058',
    projectId: 'studymateai-83db5',
    storageBucket: 'studymateai-83db5.firebasestorage.app',
  );
}
