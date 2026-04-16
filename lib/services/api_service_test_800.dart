import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../core/models/task.dart';
import '../core/models/user.dart';
import '../core/models/header_model.dart';
import '../core/models/app_notification.dart';
import '../core/models/account_connection.dart';
import '../core/utils/runtime_url_resolver.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiService {
  // /api/v1   public market data, signals, risk, paper trading
  static const String apiV1  = '/api/v1';
  // /v1/api   authenticated endpoints (tasks, accounts, forex, advanced)
  static const String apiV1b = '/v1/api';

  // added new cosntant here
  static const String apiV1c = '/v1';


  static const String _baseUrlFromDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const Duration _timeout     = Duration(seconds: 10);
  static const Duration _authTimeout = Duration(seconds: 45);

  static const String _devUserId = String.fromEnvironment(
    'DEV_USER_ID',
    defaultValue: '',
  );
  static const bool _allowDebugUserFallback = bool.fromEnvironment(
    'ALLOW_DEBUG_USER_FALLBACK',
    defaultValue: true,
  );
  static const bool _allowInsecureHttpInRelease = bool.fromEnvironment(
    'ALLOW_INSECURE_HTTP_IN_RELEASE',
    defaultValue: false,
  );
  static const bool _requireAuthInRelease = bool.fromEnvironment(
    'REQUIRE_AUTH_IN_RELEASE',
    defaultValue: true,
  );
  static const String _devAuthSharedSecret = String.fromEnvironment(
    'DEV_AUTH_SHARED_SECRET',
    defaultValue: '',
  );

  static const String _defaultDevUserId = 'dev_user_001';

  static final RegExp _invisibleChars = RegExp(
    r'[\u0000-\u001F\u007F\u00A0\u1680\u180E\u2000-\u200F\u2028-\u202F\u205F-\u206F\u3000\uFEFF]',
  );

  // -- Base URL ----------------------------------------------------------------

  static String get baseUrl {
    final fromDefine = _baseUrlFromDefine.trim();
    if (fromDefine.isNotEmpty) return _normalizeBaseUrl(fromDefine);

    final currentOrigin = resolveCurrentWebOrigin();
    if (currentOrigin != null && currentOrigin.isNotEmpty) return currentOrigin;

    if (!kDebugMode) {
      throw StateError('API_BASE_URL must be configured for non-debug builds.');
    }

    final fallback = kIsWeb ? 'http://localhost:8080' : 'http://127.0.0.1:8080';
    return _normalizeBaseUrl(fallback);
  }

  final http.Client _client = http.Client();

  // -- Static helpers ----------------------------------------------------------

  static String _normalizeBaseUrl(String v) =>
      v.endsWith('/') ? v.substring(0, v.length - 1) : v;

  static Map<String, String> _buildBaseHeaders() => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static String _normalizeEmail(String raw) => raw
      .replaceAll(_invisibleChars, '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim()
      .toLowerCase();

  static List<String> _normalizePairs(List<String>? pairs) {
    if (pairs == null) return const [];
    return pairs.map((p) => p.trim().toUpperCase()).where((p) => p.isNotEmpty).toList();
  }

  static Map<String, T> _filterRatesForPairs<T>(
    Map<String, T> rates,
    List<String> pairs,
  ) {
    if (pairs.isEmpty) return rates;
    final out = <String, T>{};
    for (final pair in pairs) {
      if (rates.containsKey(pair)) { out[pair] = rates[pair]!; continue; }
      final compact = pair.replaceAll('/', '');
      if (rates.containsKey(compact)) out[compact] = rates[compact]!;
    }
    return out.isNotEmpty ? out : rates;
  }

  static bool get _isLocalApiTarget {
    try {
      final host = Uri.parse(baseUrl).host.toLowerCase();
      return host == 'localhost' || host == '127.0.0.1';
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the Railway backend responds to /health within 5 seconds.
static Future<bool> isHealthy() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/health'),
    ).timeout(const Duration(seconds: 5));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

  static void _assertReleaseTransportSecurity() {
    if (kDebugMode || _allowInsecureHttpInRelease || _isLocalApiTarget) return;
    if (baseUrl.toLowerCase().startsWith('http://')) {
      throw ApiException('Insecure API URL blocked in release. Use https://.');
    }
  }

  String? _resolveDevUserForCurrentContext() {
    final explicit = _devUserId.trim();
    if (explicit.isNotEmpty) return explicit;
    if (kDebugMode && _allowDebugUserFallback && _isLocalApiTarget) {
      return _defaultDevUserId;
    }
    return null;
  }

  Future<String> _resolveUserId({Map<String, String>? headers}) async {
    final candidate = headers?['x-user-id']?.trim();
    if (candidate != null && candidate.isNotEmpty) return candidate;
    try {
      final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid.trim();
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {}
    throw ApiException('User identity unavailable for this request.');
  }

  Future<Map<String, String>> _buildHeaders() async {
    _assertReleaseTransportSecurity();
    final headers = <String, String>{..._buildBaseHeaders()};

    final devUserId = _resolveDevUserForCurrentContext();
    if (devUserId != null) {
      headers['x-user-id'] = devUserId;
      if (_devAuthSharedSecret.isNotEmpty) {
        headers['x-dev-auth'] = _devAuthSharedSecret;
      }
    }

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Auth header skipped: $e');
    }

    if (!kDebugMode &&
        _requireAuthInRelease &&
        !headers.containsKey('Authorization') &&
        !headers.containsKey('x-user-id')) {
      throw ApiException('Authentication is required in release mode.');
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      debugPrint('Response ${response.statusCode}: ${response.body}');
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = json.decode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = null;
      }
    }

    bool isEnvelope(Map<String, dynamic> p) =>
        p.containsKey('status') && p.containsKey('message') && p.containsKey('data');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded == null) return {};
      if (decoded is Map<String, dynamic> && isEnvelope(decoded)) {
        final status  = (decoded['status'] ?? '').toString().toLowerCase();
        final message = (decoded['message'] ?? '').toString().trim();
        if (status == 'error') {
          throw ApiException(message.isNotEmpty ? message : 'Request failed', response.statusCode);
        }
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          if (message.isNotEmpty && !data.containsKey('message')) data['message'] = message;
          return data;
        }
        if (data is List) return data;
        if (data == null) return {if (message.isNotEmpty) 'message': message};
        return {'value': data, if (message.isNotEmpty) 'message': message};
      }
      return decoded;
    }

    var message = 'API Error: ${response.statusCode} - ${response.reasonPhrase}';
    if (decoded is Map<String, dynamic>) {
      if (isEnvelope(decoded)) {
        final m = (decoded['message'] ?? '').toString().trim();
        if (m.isNotEmpty) message = m;
      }
      final detail = decoded['detail'] ?? decoded['message'] ?? decoded['error'];
      if (detail is String && detail.trim().isNotEmpty) {
        message = detail.trim();
      } else if (detail != null) {
        message = detail.toString();
      }
    } else if (response.body.isNotEmpty) {
      final plain = utf8.decode(response.bodyBytes).trim();
      if (plain.isNotEmpty) message = plain;
    }
    throw ApiException(message, response.statusCode);
  }

  // -- Fallback data -----------------------------------------------------------

  Map<String, double> _fallbackForexRates() => {
        'EUR/USD': 1.0834, 'GBP/USD': 1.2712, 'USD/JPY': 154.22,
        'USD/PKR': 278.90, 'AUD/USD': 0.6513, 'USD/CAD': 1.3611,
        'NZD/USD': 0.5989, 'USD/CHF': 0.7895,
      };

  double _fallbackPairPrice(String pair) {
    const prices = {
      'USD/PKR': 279.0, 'EUR/USD': 1.0834, 'GBP/USD': 1.2712,
      'USD/JPY': 154.22, 'AUD/USD': 0.6513, 'USD/CAD': 1.3611,
      'NZD/USD': 0.5989,
    };
    return prices[pair.toUpperCase().replaceAll(' ', '')] ?? 1.0;
  }

  int _pairDigits(String pair) {
    final p = pair.toUpperCase();
    return (p.contains('JPY') || p.contains('PKR')) ? 2 : 4;
  }

  double _formatPrice(String pair, double value) =>
      double.parse(value.toStringAsFixed(_pairDigits(pair)));

  int _stableHash(String value) {
    var hash = 0;
    for (final c in value.codeUnits) hash = (hash * 31 + c) & 0x7fffffff;
    return hash;
  }

  List<Map<String, dynamic>> _buildFallbackSignals(List<String> pairs) {
    final now   = DateTime.now();
    final rates = _fallbackForexRates();
    const timeframes = ['M30', 'H1', 'H4'];
    return pairs.map((pair) {
      final hash = _stableHash(pair);
      final type = switch (hash % 4) {
        0 => 'buy', 1 => 'sell', 2 => 'hold', _ => 'wait',
      };
      final baseConf  = 0.55 + (hash % 30) / 100;
      final confidence = (type == 'hold' || type == 'wait'
          ? (baseConf - 0.12).clamp(0.4, 0.7)
          : baseConf.clamp(0.55, 0.9)).toDouble();
      final entry = rates[pair] ?? _fallbackPairPrice(pair);
      final swing = entry * (0.0025 + (hash % 8) / 10000);
      final tp = type == 'buy'  ? entry + swing * 1.6
               : type == 'sell' ? entry - swing * 1.6 : null;
      final sl = type == 'buy'  ? entry - swing
               : type == 'sell' ? entry + swing       : null;
      final reason = switch (type) {
        'buy'  => 'Momentum aligned with higher-timeframe support; risk skew favors upside.',
        'sell' => 'Price rejected near resistance; short-term risk bias leans lower.',
        'hold' => 'Signals are mixed; waiting for confirmation before committing.',
        _      => 'Low volatility regime. Awaiting breakout and volume confirmation.',
      };
      return <String, dynamic>{
        'pair': pair, 'signal': type, 'confidence': confidence, 'reason': reason,
        'entry_price': (type == 'buy' || type == 'sell') ? _formatPrice(pair, entry) : null,
        'take_profit': tp != null ? _formatPrice(pair, tp) : null,
        'stop_loss':   sl != null ? _formatPrice(pair, sl) : null,
        'timeframe':   timeframes[hash % timeframes.length],
        'generated_at': now.subtract(Duration(minutes: hash % 45)).toIso8601String(),
        'tags': ['Fallback', type == 'hold' || type == 'wait' ? 'Neutral' : 'Momentum'],
      };
    }).toList();
  }

  void dispose() => _client.close();
}
