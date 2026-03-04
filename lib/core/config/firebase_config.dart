import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // Production fallback values for Forex Companion web app.
  // These are Firebase public web config values (not secrets).
  static const String _fallbackApiKey = 'AIzaSyAGPIvZvdbyrXwRJonYmSZvUHhGEmapec8';
  static const String _fallbackAppId = '1:238745148522:web:91d07c07f4edf09026be13';
  static const String _fallbackMessagingSenderId = '238745148522';
  static const String _fallbackProjectId = 'forexcompanion-e5a28';
  static const String _fallbackAuthDomain = 'forexcompanion-e5a28.firebaseapp.com';
  static const String _fallbackDatabaseUrl = 'https://forexcompanion-e5a28-default-rtdb.firebaseio.com';
  static const String _fallbackStorageBucket = 'forexcompanion-e5a28.firebasestorage.app';
  static const String _fallbackMeasurementId = 'G-F24QVTGL77';

  static const String _apiKeyDefine = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: _fallbackApiKey,
  );
  static const String _appIdDefine = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: _fallbackAppId,
  );
  static const String _messagingSenderIdDefine = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: _fallbackMessagingSenderId,
  );
  static const String _projectIdDefine = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: _fallbackProjectId,
  );
  static const String _authDomainDefine = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: _fallbackAuthDomain,
  );
  static const String _databaseUrlDefine = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: _fallbackDatabaseUrl,
  );
  static const String _storageBucketDefine = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: _fallbackStorageBucket,
  );
  static const String _measurementIdDefine = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: _fallbackMeasurementId,
  );

  static String _read(String defineValue) => defineValue.trim();

  static String get _apiKey => _read(_apiKeyDefine);
  static String get _appId => _read(_appIdDefine);
  static String get _messagingSenderId => _read(_messagingSenderIdDefine);
  static String get _projectId => _read(_projectIdDefine);
  static String get _authDomain => _read(_authDomainDefine);
  static String get _databaseUrl => _read(_databaseUrlDefine);
  static String get _storageBucket => _read(_storageBucketDefine);
  static String get _measurementId => _read(_measurementIdDefine);

  static void validate() {
    final requiredKeys = <String, String>{
      'FIREBASE_API_KEY': _apiKey,
      'FIREBASE_APP_ID': _appId,
      'FIREBASE_MESSAGING_SENDER_ID': _messagingSenderId,
      'FIREBASE_PROJECT_ID': _projectId,
      'FIREBASE_AUTH_DOMAIN': _authDomain,
      'FIREBASE_STORAGE_BUCKET': _storageBucket,
    };

    final missing = requiredKeys.entries
        .where((entry) => entry.value.trim().isEmpty)
        .map((entry) => entry.key)
        .toList();

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing Firebase configuration: ${missing.join(', ')}',
      );
    }
  }

  static FirebaseOptions get currentPlatform {
    validate();
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _authDomain,
        databaseURL: _databaseUrl.isEmpty ? null : _databaseUrl,
        storageBucket: _storageBucket,
        measurementId: _measurementId.isEmpty ? null : _measurementId,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // Use the same env-backed config until platform-specific IDs are split.
        return FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          authDomain: _authDomain,
          databaseURL: _databaseUrl.isEmpty ? null : _databaseUrl,
          storageBucket: _storageBucket,
          measurementId: _measurementId.isEmpty ? null : _measurementId,
        );
      default:
        throw UnsupportedError(
          'Firebase configuration is not supported for this platform.',
        );
    }
  }
}
