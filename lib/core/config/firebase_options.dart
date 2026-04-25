// ⚠️  THIS FILE IS A PLACEHOLDER.
//
// You MUST regenerate this file using:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=forexcompanion-e5a28
//
// That command writes the REAL keys and google-services data.
// Do NOT hand-edit — auto-generated values only.
//
// See Task 2.1 in Tajir_Handoff_April25_2026.docx

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── Web ─────────────────────────────────────────────────────────────────
  // Values from lib/core/config/firebase_config.dart (already extracted)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC-REPLACE-WITH-REAL-KEY-FROM-FLUTTERFIRE',
    appId: '1:REPLACE:web:REPLACE',
    messagingSenderId: 'REPLACE',
    projectId: 'forexcompanion-e5a28',
    authDomain: 'forexcompanion-e5a28.firebaseapp.com',
    storageBucket: 'forexcompanion-e5a28.appspot.com',
  );

  // ── Android ─────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC-REPLACE-WITH-REAL-KEY-FROM-FLUTTERFIRE',
    appId: '1:REPLACE:android:REPLACE',
    messagingSenderId: 'REPLACE',
    projectId: 'forexcompanion-e5a28',
    storageBucket: 'forexcompanion-e5a28.appspot.com',
  );

  // ── iOS ──────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC-REPLACE-WITH-REAL-KEY-FROM-FLUTTERFIRE',
    appId: '1:REPLACE:ios:REPLACE',
    messagingSenderId: 'REPLACE',
    projectId: 'forexcompanion-e5a28',
    storageBucket: 'forexcompanion-e5a28.appspot.com',
    iosClientId: 'REPLACE.apps.googleusercontent.com',
    iosBundleId: 'com.tajir.tajir',
  );
}
