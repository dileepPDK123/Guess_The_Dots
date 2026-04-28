// File generated for the Guess the Dots Flutter app.
// Hand-written from the values fetched via the Firebase MCP earlier
// (project guess-the-dots-ce3ff). For per-platform overrides use the native
// google-services.json (Android) and GoogleService-Info.plist (iOS).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      default:
        return _web;
    }
  }

  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: 'AIzaSyBnIIhjYBa3rIRnE9SiRFEg7ACUZNFMmaM',
    appId: '1:197855415872:web:2cc7d7d0757ccc86ae99a5',
    messagingSenderId: '197855415872',
    projectId: 'guess-the-dots-ce3ff',
    authDomain: 'guess-the-dots-ce3ff.firebaseapp.com',
    storageBucket: 'guess-the-dots-ce3ff.firebasestorage.app',
    measurementId: 'G-VK9JYWY5LM',
  );

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyAP03ojMVQmnsfVHGYcnud9XfaVv_zCNrQ',
    appId: '1:197855415872:android:10af282e53d014deae99a5',
    messagingSenderId: '197855415872',
    projectId: 'guess-the-dots-ce3ff',
    storageBucket: 'guess-the-dots-ce3ff.firebasestorage.app',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyBdndgtovXnZCDJaVO1-W78K3DcCbSMMsg',
    appId: '1:197855415872:ios:da20fd427dc1393eae99a5',
    messagingSenderId: '197855415872',
    projectId: 'guess-the-dots-ce3ff',
    storageBucket: 'guess-the-dots-ce3ff.firebasestorage.app',
    iosBundleId: 'com.dileepkumar.guessthedots',
  );
}
