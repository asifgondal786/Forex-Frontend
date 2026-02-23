import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  static const String _apiKeyDefine = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );
  static const String _appIdDefine = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );
  static const String _messagingSenderIdDefine = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
  static const String _projectIdDefine = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );
  static const String _authDomainDefine = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: '',
  );
  static const String _databaseUrlDefine = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: '',
  );
  static const String _storageBucketDefine = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );
  static const String _measurementIdDefine = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: '',
  );

  static String _env(String key) => (dotenv.env[key] ?? '').trim();

  static String _read(String key, String defineValue) {
    final fromDefine = defineValue.trim();
    if (fromDefine.isNotEmpty) return fromDefine;
    return _env(key);
  }

  static String get _apiKey => _read('FIREBASE_API_KEY', _apiKeyDefine);
  static String get _appId => _read('FIREBASE_APP_ID', _appIdDefine);
  static String get _messagingSenderId =>
      _read('FIREBASE_MESSAGING_SENDER_ID', _messagingSenderIdDefine);
  static String get _projectId => _read('FIREBASE_PROJECT_ID', _projectIdDefine);
  static String get _authDomain => _read('FIREBASE_AUTH_DOMAIN', _authDomainDefine);
  static String get _databaseUrl => _read('FIREBASE_DATABASE_URL', _databaseUrlDefine);
  static String get _storageBucket =>
      _read('FIREBASE_STORAGE_BUCKET', _storageBucketDefine);
  static String get _measurementId =>
      _read('FIREBASE_MEASUREMENT_ID', _measurementIdDefine);

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
