import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // It's strongly recommended to load the API key from a secure source,
  // such as environment variables, rather than hardcoding it.
  // Use --dart-define=FIREBASE_API_KEY=YOUR_API_KEY
  // For local development, you can temporarily hardcode it here.
  static const String _apiKey = 'AIzaSyAGPIvZvdbyrXwRJonYmSZvUHhGEmapec8'; 

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web Configuration - YOUR ACTUAL FIREBASE PROJECT
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:238745148522:web:91d07c07f4edf09026be13',
    messagingSenderId: '238745148522',
    projectId: 'forexcompanion-e5a28',
    authDomain: 'forexcompanion-e5a28.firebaseapp.com',
    databaseURL: 'https://forexcompanion-e5a28-default-rtdb.firebaseio.com',
    storageBucket: 'forexcompanion-e5a28.firebasestorage.app',
    measurementId: 'G-F24QVTGL77',
  );

  // Android Configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:238745148522:android:YOUR_ANDROID_APP_ID',
    messagingSenderId: '238745148522',
    projectId: 'forexcompanion-e5a28',
    storageBucket: 'forexcompanion-e5a28.firebasestorage.app',
  );

  // iOS Configuration  
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:238745148522:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '238745148522',
    projectId: 'forexcompanion-e5a28',
    storageBucket: 'forexcompanion-e5a28.firebasestorage.app',
    iosBundleId: 'com.forexcompanion.app',
  );

  // macOS Configuration
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:238745148522:macos:YOUR_MACOS_APP_ID',
    messagingSenderId: '238745148522',
    projectId: 'forexcompanion-e5a28',
    storageBucket: 'forexcompanion-e5a28.firebasestorage.app',
    iosBundleId: 'com.forexcompanion.app',
  );
}