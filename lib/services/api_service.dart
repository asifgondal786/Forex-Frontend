import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../core/models/user.dart';
import '../core/models/app_notification.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiService {
  // /api/v1 — public market data, signals, risk, paper trading
  static const String apiV1  = '/api/v1';
  // /v1/api — authenticated endpoints (accounts, forex, advanced)
  static const String apiV1b = '/v1/api';
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

  // ── Agent controls ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchAgentStatus() async =>
      await _get('/api/v1/agent/status');

  Future<Map<String, dynamic>> startAgent() async =>
      await _post('/api/v1/agent/start', {});

  Future<Map<String, dynamic>> stopAgent() async =>
      await _post('/api/v1/agent/stop', {});

  Future<Map<String, dynamic>> killAgent() async =>
      await _post('/api/v1/agent/kill', {});

  Future<Map<String, dynamic>> approveTrade(String tradeId) async =>
      await _post('/api/v1/agent/approve', {'trade_id': tradeId});

  Future<Map<String, dynamic>> rejectTrade(String tradeId) async =>
      await _post('/api/v1/agent/reject', {'trade_id': tradeId});

  Future<Map<String, dynamic>> updateRiskSettings(
          Map<String, dynamic> settings) async =>
      await _post('/api/v1/agent/risk', settings);

  Future<Map<String, dynamic>> sendNlpChat(String message) async =>
      await _post('/api/v1/nlp/chat', {'message': message});

  Future<Map<String, dynamic>> fetchNews() async =>
      await _get('/api/v1/news');

  Future<Map<String, dynamic>> fetchMarketSentiment() async =>
      await _get('/api/v1/market/sentiment');

  // ── Base URL ──────────────────────────────────────────────────────────────
  static String get baseUrl {
    final fromDefine = _baseUrlFromDefine.trim();
    if (fromDefine.isNotEmpty) return _normalizeBaseUrl(fromDefine);

    if (!kDebugMode) {
      throw StateError('API_BASE_URL must be configured for non-debug builds.');
    }

    final fallback = kIsWeb ? 'http://127.0.0.1:8001' : 'http://127.0.0.1:8001';
    return _normalizeBaseUrl(fallback);
  }

  final http.Client _client = http.Client();

  // ── Static helpers ────────────────────────────────────────────────────────
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
    return pairs
        .map((p) => p.trim().toUpperCase())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  static Map<String, T> _filterRatesForPairs<T>(
    Map<String, T> rates,
    List<String> pairs,
  ) {
    if (pairs.isEmpty) return rates;
    final out = <String, T>{};
    for (final pair in pairs) {
      if (rates.containsKey(pair)) {
        out[pair] = rates[pair]!;
        continue;
      }
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

  /// Returns true if the backend responds to /health within 5 seconds.
  static Future<bool> isHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
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
      final uid =
          firebase_auth.FirebaseAuth.instance.currentUser?.uid.trim();
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

  dynamic _deepCastMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), _deepCastMap(v))),
      );
    } else if (value is List) {
      return value.map(_deepCastMap).toList();
    }
    return value;
  }

  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      debugPrint('Response ${response.statusCode}: ${response.body}');
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        var raw = json.decode(utf8.decode(response.bodyBytes));
        decoded = _deepCastMap(raw);
      } catch (_) {
        decoded = null;
      }
    }

    bool isEnvelope(Map<String, dynamic> p) =>
        p.containsKey('status') &&
        p.containsKey('message') &&
        p.containsKey('data');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded == null) return {};
      if (decoded is Map<String, dynamic> && isEnvelope(decoded)) {
        final status  = (decoded['status'] ?? '').toString().toLowerCase();
        final message = (decoded['message'] ?? '').toString().trim();
        if (status == 'error') {
          throw ApiException(
              message.isNotEmpty ? message : 'Request failed',
              response.statusCode);
        }
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          if (message.isNotEmpty && !data.containsKey('message')) {
            data['message'] = message;
          }
          return data;
        }
        if (data is List) return data;
        if (data == null) {
          return {if (message.isNotEmpty) 'message': message};
        }
        return {'value': data, if (message.isNotEmpty) 'message': message};
      }
      return decoded;
    }

    var message =
        'API Error: ${response.statusCode} - ${response.reasonPhrase}';
    if (decoded is Map<String, dynamic>) {
      if (isEnvelope(decoded)) {
        final m = (decoded['message'] ?? '').toString().trim();
        if (m.isNotEmpty) message = m;
      }
      final detail =
          decoded['detail'] ?? decoded['message'] ?? decoded['error'];
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

  // ── Private HTTP helpers ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> _get(String path) async {
    final headers  = await _buildHeaders();
    final response = await _client
        .get(Uri.parse('$baseUrl$path'), headers: headers)
        .timeout(_timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final headers  = await _buildHeaders();
    final response = await _client
        .post(Uri.parse('$baseUrl$path'),
            headers: headers, body: json.encode(body))
        .timeout(_timeout);
    return _handleResponse(response);
  }

  // ── Fallback data ─────────────────────────────────────────────────────────
  Map<String, double> _fallbackForexRates() => {
        'EUR/USD': 1.0834, 'GBP/USD': 1.2712, 'USD/JPY': 154.22,
        'USD/PKR': 278.90, 'AUD/USD': 0.6513, 'USD/CAD': 1.3611,
        'NZD/USD': 0.5989, 'USD/CHF': 0.7895,
      };

  double _fallbackPairPrice(String pair) {
    const prices = {
      'USD/PKR': 279.0,  'EUR/USD': 1.0834, 'GBP/USD': 1.2712,
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
      final baseConf   = 0.55 + (hash % 30) / 100;
      final confidence = (type == 'hold' || type == 'wait'
              ? (baseConf - 0.12).clamp(0.4, 0.7)
              : baseConf.clamp(0.55, 0.9))
          .toDouble();
      final entry = rates[pair] ?? _fallbackPairPrice(pair);
      final swing = entry * (0.0025 + (hash % 8) / 10000);
      final tp = type == 'buy'
          ? entry + swing * 1.6
          : type == 'sell'
              ? entry - swing * 1.6
              : null;
      final sl = type == 'buy'
          ? entry - swing
          : type == 'sell'
              ? entry + swing
              : null;
      final reason = switch (type) {
        'buy'  => 'Momentum aligned with higher-timeframe support.',
        'sell' => 'Price rejected near resistance; risk bias leans lower.',
        'hold' => 'Signals mixed; waiting for confirmation.',
        _      => 'Low volatility. Awaiting breakout confirmation.',
      };
      return <String, dynamic>{
        'pair': pair, 'signal': type, 'confidence': confidence,
        'reason': reason,
        'entry_price': (type == 'buy' || type == 'sell')
            ? _formatPrice(pair, entry)
            : null,
        'take_profit': tp != null ? _formatPrice(pair, tp) : null,
        'stop_loss':   sl != null ? _formatPrice(pair, sl) : null,
        'timeframe':   timeframes[hash % timeframes.length],
        'generated_at':
            now.subtract(Duration(minutes: hash % 45)).toIso8601String(),
        'tags': [
          'Fallback',
          type == 'hold' || type == 'wait' ? 'Neutral' : 'Momentum'
        ],
      };
    }).toList();
  }

  // =========================================================================
  // USER ENDPOINTS
  // =========================================================================

  Future<Map<String, dynamic>> requestPasswordReset(
      {required String email}) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty) {
      throw ApiException('Email is required for password reset.');
    }
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/auth/password-reset'),
              headers: await _buildHeaders(),
              body: json.encode({'email': normalized}))
          .timeout(_authTimeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      return {
        'success': true,
        'message':
            'If an account exists for this email, reset instructions have been sent.',
        'debug': {'result': 'client_timeout_optimistic'},
      };
    } catch (e) {
      throw ApiException('Error requesting password reset: $e');
    }
  }

  Future<Map<String, dynamic>> requestEmailVerification(
      {required String email}) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty) {
      throw ApiException('Email is required for verification.');
    }
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/auth/email-verification'),
              headers: await _buildHeaders(),
              body: json.encode({'email': normalized}))
          .timeout(_authTimeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error requesting verification email: $e');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final headers  = await _buildHeaders();
      final response = await _client
          .get(Uri.parse('$baseUrl$apiV1c/users/me'), headers: headers)
          .timeout(_timeout);
      return User.fromJson(_handleResponse(response));
    } catch (e) {
      throw ApiException('Error fetching user: $e');
    }
  }

  Future<User> updateUser({String? name, String? email}) async {
    try {
      final body = <String, dynamic>{};
      if (name  != null) body['name']  = name;
      if (email != null) body['email'] = email;
      final headers  = await _buildHeaders();
      final response = await _client
          .put(Uri.parse('$baseUrl$apiV1c/users/me'),
              headers: headers, body: json.encode(body))
          .timeout(_timeout);
      return User.fromJson(_handleResponse(response));
    } catch (e) {
      throw ApiException('Error updating user: $e');
    }
  }

  // =========================================================================
  // NOTIFICATION ENDPOINTS
  // =========================================================================

  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 20,
  }) async {
    try {
      final headers = await _buildHeaders();
      final uri     = Uri.parse('$baseUrl$apiV1b/notifications').replace(
        queryParameters: {
          'unread_only': '$unreadOnly',
          'limit': '$limit',
        },
      );
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);
      final data  = _handleResponse(response);
      final items = data is List
          ? data
          : (data is Map ? data['notifications'] : null);
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map((j) => AppNotification.fromJson(j))
            .toList();
      }
      throw ApiException('Invalid notifications response');
    } catch (e) {
      throw ApiException('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      final headers  = await _buildHeaders();
      final response = await _client
          .post(
              Uri.parse(
                  '$baseUrl$apiV1b/notifications/$notificationId/read'),
              headers: headers)
          .timeout(_timeout);
      _handleResponse(response);
    } catch (e) {
      throw ApiException('Error marking notification read: $e');
    }
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final headers  = await _buildHeaders();
      final response = await _client
          .get(Uri.parse('$baseUrl$apiV1b/notifications/preferences'),
              headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error fetching notification preferences: $e');
    }
  }

  Future<Map<String, dynamic>> setNotificationPreferences({
    List<String>? enabledChannels,
    List<String>? disabledCategories,
    String? quietHoursStart,
    String? quietHoursEnd,
    int? maxPerHour,
    bool? digestMode,
    bool? autonomousMode,
    String? autonomousProfile,
    double? autonomousMinConfidence,
    bool? autonomousStageAlerts,
    int? autonomousStageIntervalSeconds,
    Map<String, dynamic>? channelSettings,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (enabledChannels != null) body['enabled_channels'] = enabledChannels;
      if (disabledCategories != null) {
        body['disabled_categories'] = disabledCategories;
      }
      if (quietHoursStart != null) body['quiet_hours_start'] = quietHoursStart;
      if (quietHoursEnd   != null) body['quiet_hours_end']   = quietHoursEnd;
      if (maxPerHour      != null) body['max_per_hour']      = maxPerHour;
      if (digestMode      != null) body['digest_mode']       = digestMode;
      if (autonomousMode  != null) body['autonomous_mode']   = autonomousMode;
      if (autonomousProfile != null) {
        body['autonomous_profile'] = autonomousProfile;
      }
      if (autonomousMinConfidence != null) {
        body['autonomous_min_confidence'] = autonomousMinConfidence;
      }
      if (autonomousStageAlerts != null) {
        body['autonomous_stage_alerts'] = autonomousStageAlerts;
      }
      if (autonomousStageIntervalSeconds != null) {
        body['autonomous_stage_interval_seconds'] =
            autonomousStageIntervalSeconds;
      }
      if (channelSettings != null) body['channel_settings'] = channelSettings;

      final headers  = await _buildHeaders();
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1b/notifications/preferences'),
              headers: headers, body: json.encode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error setting notification preferences: $e');
    }
  }

  Future<Map<String, dynamic>> sendNotification({
    required String templateId,
    required String category,
    String priority = 'medium',
    Map<String, dynamic> variables = const {},
  }) async {
    try {
      final headers  = await _buildHeaders();
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1b/notifications/send'),
              headers: headers,
              body: json.encode({
                'template_id': templateId,
                'category':    category,
                'priority':    priority,
                'variables':   variables,
              }))
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error sending notification: $e');
    }
  }

  Future<Map<String, dynamic>> getNotificationDigest(
      {String period = 'daily'}) async {
    try {
      final headers  = await _buildHeaders();
      final uri      = Uri.parse('$baseUrl$apiV1b/notifications/digest')
          .replace(queryParameters: {'period': period});
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error fetching notification digest: $e');
    }
  }

  Future<Map<String, dynamic>> getDeepMarketStudy({
    String pair = 'EUR/USD',
    int maxHeadlinesPerSource = 3,
  }) async {
    try {
      final headers = await _buildHeaders();
      final uri     =
          Uri.parse('$baseUrl$apiV1b/notifications/deep-study').replace(
        queryParameters: {
          'pair': pair.trim().toUpperCase(),
          'max_headlines_per_source': '$maxHeadlinesPerSource',
        },
      );
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {
        'pair':              pair.trim().toUpperCase(),
        'confidence_band':   'low',
        'recommendation':    'wait_for_confirmation',
        'source_coverage':   {'requested': 0, 'analyzed': 0, 'coverage_ratio': 0.0},
      };
    }
  }

  // =========================================================================
  // MARKET DATA ENDPOINTS  (/api/v1 — no auth required)
  // =========================================================================

  Future<List<Map<String, dynamic>>> fetchMarketPrices({
    List<String> pairs = const ['EUR_USD', 'GBP_USD', 'USD_JPY'],
  }) async {
    final backendPairs =
        pairs.map((p) => p.toUpperCase().replaceAll('/', '_')).toList();
    try {
      final uri = Uri.parse('$baseUrl$apiV1/market/prices').replace(
        queryParameters: {'pairs': backendPairs.join(',')},
      );
      final response = await _client.get(uri).timeout(_timeout);
      final data     = _handleResponse(response);
      if (data is Map<String, dynamic> && data['prices'] is List) {
        return (data['prices'] as List).cast<Map<String, dynamic>>();
      }
      return _fallbackMarketPrices(backendPairs);
    } catch (e) {
      return _fallbackMarketPrices(backendPairs);
    }
  }

  List<Map<String, dynamic>> _fallbackMarketPrices(
      List<String> backendPairs) {
    final rates = _fallbackForexRates();
    final now   = DateTime.now().toUtc().toIso8601String();
    return backendPairs.map((instr) {
      final slashPair = instr.replaceAll('_', '/');
      final mid       = rates[slashPair] ?? _fallbackPairPrice(slashPair);
      final spread    = instr.contains('JPY') ? 0.012 : 0.0002;
      return <String, dynamic>{
        'instrument': instr,
        'bid':        _formatPrice(slashPair, mid - spread / 2),
        'ask':        _formatPrice(slashPair, mid + spread / 2),
        'mid':        _formatPrice(slashPair, mid),
        'spread':     instr.contains('JPY') ? 1.2 : 1.0,
        'tradeable':  false,
        'timestamp':  now,
        'source':     'fallback',
      };
    }).toList();
  }

  Future<Map<String, dynamic>> fetchOHLCData({
    String pair      = 'EUR/USD',
    String interval  = '1h',
    int outputsize   = 100,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl$apiV1/market/ohlc?pair=${Uri.encodeComponent(pair)}&interval=$interval&outputsize=$outputsize');
      final response = await _client.get(uri).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {'values': []};
    }
  }

  // =========================================================================
  // SIGNALS & NEWS ENDPOINTS
  // =========================================================================

  Future<List<Map<String, dynamic>>> fetchLiveSignals({
    List<String> pairs = const ['EUR_USD', 'GBP_USD', 'USD_JPY'],
  }) async {
    try {
      final uri      =
          Uri.parse('$baseUrl$apiV1/signals/generate?pairs=${pairs.join(',')}');
      final headers  = await _buildHeaders();
      final response =
          await _client.post(uri, headers: headers).timeout(_timeout);
      final data     = _handleResponse(response);
      return (data['signals'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchNewsFeed(
      {String pair = 'EUR/USD'}) async {
    try {
      final uri =
          Uri.parse('$baseUrl$apiV1/news/feed?pair=${Uri.encodeComponent(pair)}');
      final response = await _client.get(uri).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {'top_headlines': [], 'status': 'error'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchEconomicEvents({
    int hours          = 48,
    bool highImpactOnly = false,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl$apiV1/news/events?hours=$hours&high_impact_only=$highImpactOnly');
      final response = await _client.get(uri).timeout(_timeout);
      final data     = _handleResponse(response);
      return (data['events'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // =========================================================================
  // FOREX DATA ENDPOINTS  (/v1/api — authenticated)
  // =========================================================================

  Future<Map<String, dynamic>> getForexRates({List<String>? pairs}) async {
    final normalized = _normalizePairs(pairs);
    try {
      final headers = await _buildHeaders();
      final uri     = Uri.parse('$baseUrl$apiV1b/forex/rates').replace(
        queryParameters:
            normalized.isEmpty ? null : {'pairs': normalized.join(',')},
      );
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);
      final data = _handleResponse(response);
      if (normalized.isNotEmpty && data is Map<String, dynamic>) {
        final rates = data['rates'];
        if (rates is Map<String, dynamic>) {
          data['rates'] = _filterRatesForPairs(rates, normalized);
        }
      }
      return data;
    } catch (e) {
      return {
        'status': 'fallback',
        'rates': _filterRatesForPairs(_fallbackForexRates(), normalized),
      };
    }
  }

  Future<Map<String, dynamic>> getForexNews() async {
    try {
      final headers  = await _buildHeaders();
      final response = await _client
          .get(Uri.parse('$baseUrl$apiV1b/forex/news'), headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'fallback',
        'news': [
          {
            'time': DateTime.now().toIso8601String(),
            'currency': 'USD', 'impact': 'high',
            'event': 'US labor market update',
            'actual': 'N/A', 'forecast': 'N/A', 'previous': 'N/A',
          },
          {
            'time': DateTime.now()
                .subtract(const Duration(minutes: 30))
                .toIso8601String(),
            'currency': 'EUR', 'impact': 'medium',
            'event': 'Eurozone inflation watch',
            'actual': 'N/A', 'forecast': 'N/A', 'previous': 'N/A',
          },
        ],
      };
    }
  }

  Future<Map<String, dynamic>> getForexMarketSentiment() async {
    try {
      final headers  = await _buildHeaders();
      final response = await _client
          .get(Uri.parse('$baseUrl$apiV1b/forex/sentiment'),
              headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {
        'status': 'fallback',
        'sentiment': {
          'trend': 'neutral', 'volatility': 'medium',
          'risk_level': 'moderate',
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    }
  }

  Future<Map<String, dynamic>> getTradeSignals({List<String>? pairs}) async {
    final normalized  = _normalizePairs(pairs);
    final targetPairs = normalized.isEmpty
        ? const <String>['EUR/USD', 'GBP/USD', 'USD/JPY']
        : normalized;
    try {
      final headers = await _buildHeaders();
      final uri     = Uri.parse('$baseUrl$apiV1b/forex/signals').replace(
        queryParameters:
            targetPairs.isEmpty ? null : {'pairs': targetPairs.join(',')},
      );
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);
      final data = _handleResponse(response);
      return data is Map<String, dynamic> ? data : {'signals': data};
    } catch (e) {
      return {
        'status': 'fallback',
        'signals': _buildFallbackSignals(targetPairs),
      };
    }
  }

  Future<Map<String, dynamic>> getForexPairForecast({
    required String pair,
    String horizon = '1d',
  }) async {
    final normPair    = pair.trim().toUpperCase();
    final normHorizon = horizon.trim().toLowerCase();
    try {
      final headers = await _buildHeaders();
      final uri     = Uri.parse('$baseUrl$apiV1b/forex/forecast').replace(
        queryParameters: {'pair': normPair, 'horizon': normHorizon},
      );
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      final price  = _fallbackPairPrice(normPair);
      final digits = _pairDigits(normPair);
      return {
        'status': 'fallback',
        'forecast': {
          'pair': normPair, 'horizon': normHorizon,
          'generated_at': DateTime.now().toIso8601String(),
          'current_price': double.parse(price.toStringAsFixed(digits)),
          'trend_bias': 'neutral', 'volatility': 'medium',
          'risk_level': 'moderate', 'confidence_percent': 58,
          'expected_change_percent': {'low': -0.4, 'mid': 0.2, 'high': 0.8},
          'target_range': {
            'low':  double.parse((price * 0.996).toStringAsFixed(digits)),
            'high': double.parse((price * 1.006).toStringAsFixed(digits)),
          },
          'disclaimer': 'Simulation-grade forecast. Not financial advice.',
        },
      };
    }
  }

  // =========================================================================
  // FEATURES / ADVANCED ENDPOINTS
  // =========================================================================

  Future<Map<String, dynamic>> parseNaturalLanguageCommand(
      String command) async {
    try {
      final headers  = await _buildHeaders();
      final uri      =
          Uri.parse('$baseUrl$apiV1b/advanced/nlp/parse-command')
              .replace(queryParameters: {'text': command});
      final response =
          await _client.post(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false, 'confidence': 0.0,
        'command_type': 'unknown',
        'ai_response': 'Command parser unavailable.',
      };
    }
  }

  Future<Map<String, dynamic>> getFeaturesStatus() async {
    try {
      final headers  = await _buildHeaders();
      final userId   = await _resolveUserId(headers: headers);
      final response = await _client
          .get(
              Uri.parse(
                  '$baseUrl$apiV1b/advanced/features/status?user_id=$userId'),
              headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      final now = DateTime.now().toIso8601String();
      return {
        'success': true, 'timestamp': now,
        'features': {
          'smart_triggers':     {'active': true, 'count': 0, 'status': 'active', 'last_updated': now},
          'realtime_charts':    {'active': true, 'status': 'connected', 'last_updated': now},
          'news_aware':         {'active': true, 'sentiment': 'neutral', 'last_updated': now},
          'autonomous_actions': {'active': true, 'risk_level': 'moderate', 'last_updated': now},
        },
      };
    }
  }

  // =========================================================================
  // SECURITY & COMPLIANCE
  // =========================================================================

  Future<Map<String, dynamic>> getSecurityDashboard() async {
    try {
      final headers  = await _buildHeaders();
      final userId   = await _resolveUserId(headers: headers);
      final response = await _client
          .get(
              Uri.parse(
                  '$baseUrl$apiV1b/advanced/security/dashboard/$userId'),
              headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error fetching security dashboard: $e');
    }
  }

  Future<Map<String, dynamic>> getAutonomyGuardrails() async {
    try {
      final headers  = await _buildHeaders();
      final userId   = await _resolveUserId(headers: headers);
      final response = await _client
          .get(
              Uri.parse(
                  '$baseUrl$apiV1b/advanced/autonomy/guardrails/$userId'),
              headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error fetching autonomy guardrails: $e');
    }
  }

  Future<Map<String, dynamic>> configureAutonomyGuardrails({
    String? level,
    Map<String, dynamic>? probation,
    Map<String, dynamic>? riskBudget,
    String? profile,
  }) async {
    try {
      final headers = await _buildHeaders();
      final userId  = await _resolveUserId(headers: headers);
      final body    = <String, dynamic>{'user_id': userId};
      if (level?.trim().isNotEmpty   == true) body['level']   = level!.trim().toLowerCase();
      if (profile?.trim().isNotEmpty == true) body['profile'] = profile!.trim().toLowerCase();
      if (probation  != null) body['probation']   = probation;
      if (riskBudget != null) body['risk_budget'] = riskBudget;
      final response = await _client
          .post(
              Uri.parse(
                  '$baseUrl$apiV1b/advanced/autonomy/guardrails/configure'),
              headers: headers,
              body: json.encode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error configuring autonomy guardrails: $e');
    }
  }

  Future<Map<String, dynamic>> explainBeforeExecute({
    required Map<String, dynamic> tradeParams,
  }) async {
    try {
      final headers  = await _buildHeaders();
      final userId   = await _resolveUserId(headers: headers);
      final response = await _client
          .post(
              Uri.parse(
                  '$baseUrl$apiV1b/advanced/autonomy/explain-before-execute'),
              headers: headers,
              body: json.encode(
                  {'user_id': userId, 'trade_params': tradeParams}))
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error running explain-before-execute: $e');
    }
  }

  Future<Map<String, dynamic>> executeAutonomousTrade({
    required Map<String, dynamic> tradeParams,
    String? explainToken,
  }) async {
    try {
      final headers = await _buildHeaders();
      final userId  = await _resolveUserId(headers: headers);
      final uri     = Uri.parse('$baseUrl$apiV1b/advanced/risk/execute-trade')
          .replace(queryParameters: {'user_id': userId});
      final payload = <String, dynamic>{...tradeParams};
      if (explainToken?.trim().isNotEmpty == true) {
        payload['explain_token'] = explainToken!.trim();
      }
      final response = await _client
          .post(uri, headers: headers, body: json.encode(payload))
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error executing autonomous trade: $e');
    }
  }

  Future<Map<String, dynamic>> activateKillSwitch() async {
    try {
      final headers  = await _buildHeaders();
      final userId   = await _resolveUserId(headers: headers);
      final uri      =
          Uri.parse('$baseUrl$apiV1b/advanced/risk/kill-switch')
              .replace(queryParameters: {'user_id': userId});
      final response =
          await _client.post(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error activating kill switch: $e');
    }
  }

  // =========================================================================
  // RISK GUARDIAN ENDPOINTS
  // =========================================================================

  Future<Map<String, dynamic>> fetchKellyCriterion({
    required double winRate,
    required double avgWin,
    required double avgLoss,
    required double accountBalance,
    double kellyFraction = 0.25,
  }) async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1/risk/kelly'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'win_rate': winRate, 'avg_win': avgWin,
                'avg_loss': avgLoss, 'account_balance': accountBalance,
                'kelly_fraction': kellyFraction,
              }))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Kelly error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchDrawdownControls({
    required double accountBalance,
    double dailyLossLimitPct  = 0.03,
    double weeklyLossLimitPct = 0.06,
    int maxOpenTrades         = 3,
    double riskPerTradePct    = 0.01,
  }) async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1/risk/drawdown'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'account_balance':       accountBalance,
                'daily_loss_limit_pct':  dailyLossLimitPct,
                'weekly_loss_limit_pct': weeklyLossLimitPct,
                'max_open_trades':       maxOpenTrades,
                'risk_per_trade_pct':    riskPerTradePct,
              }))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Drawdown error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchStressTest({
    required double winRate,
    required double avgWin,
    required double avgLoss,
    required double startingBalance,
    int numTrades   = 100,
    int simulations = 300,
  }) async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1/risk/stress-test'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'win_rate': winRate, 'avg_win': avgWin,
                'avg_loss': avgLoss, 'starting_balance': startingBalance,
                'num_trades': numTrades, 'simulations': simulations,
              }))
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Stress test error: $e');
    }
  }

  // =========================================================================
  // RISK SIMULATOR ENDPOINTS
  // =========================================================================

  Future<Map<String, dynamic>> fetchRiskSimulation({
    double winRate         = 0.55,
    double avgWin          = 50.0,
    double avgLoss         = 30.0,
    int numTrades          = 100,
    double startingBalance = 10000.0,
    int simulations        = 1000,
  }) async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1/risk/simulate'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'win_rate': winRate, 'avg_win': avgWin,
                'avg_loss': avgLoss, 'num_trades': numTrades,
                'starting_balance': startingBalance,
                'simulations': simulations,
              }))
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error running risk simulation: $e');
    }
  }

  // =========================================================================
  // NLP VOICE COPILOT
  // =========================================================================

  Future<Map<String, dynamic>> parseNLPCommand({
    required String text,
    double accountBalance = 10000.0,
  }) async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1/signals/nlp/parse'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(
                  {'text': text, 'account_balance': accountBalance}))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'intent': 'CHAT', 'confidence': 0.0, 'response': null};
    }
  }

  Future<Map<String, dynamic>> aiChat(
    List<Map<String, dynamic>> messages, {
    String? pair,
    Map<String, dynamic>? context,
  }) async {
    try {
      final headers = await _buildHeaders();
      final body    = <String, dynamic>{
        'messages': messages,
        if (pair?.trim().isNotEmpty == true) 'pair': pair!.trim().toUpperCase(),
        if (context != null) 'context': context,
      };
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1b/advanced/nlp/chat'),
              headers: headers, body: json.encode(body))
          .timeout(_authTimeout);
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'response': 'AI chat is temporarily unavailable.',
        'error': e.toString(),
      };
    }
  }

  // =========================================================================
  // PAPER TRADING ENDPOINTS
  // =========================================================================

  Future<Map<String, dynamic>> openPaperTrade({
    required String userId,
    required String pair,
    required String direction,
    required double entryPrice,
    required double stopLoss,
    required double takeProfit,
    double lotSize  = 1000.0,
    String? reasoning,
    String? signalId,
  }) async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1/paper/open'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'user_id': userId, 'pair': pair,
                'direction': direction, 'entry_price': entryPrice,
                'stop_loss': stopLoss, 'take_profit': takeProfit,
                'lot_size': lotSize,
                if (reasoning != null) 'reasoning': reasoning,
                if (signalId  != null) 'signal_id': signalId,
              }))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error opening paper trade: $e');
    }
  }

  Future<Map<String, dynamic>> closePaperTrade({
    required String tradeId,
    required double closePrice,
    String closeReason = 'manual',
  }) async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl$apiV1/paper/close'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'trade_id': tradeId, 'close_price': closePrice,
                'close_reason': closeReason,
              }))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Error closing paper trade: $e');
    }
  }

  Future<Map<String, dynamic>> fetchOpenPaperTrades(
      {required String userId}) async {
    try {
      final response = await _client
          .get(Uri.parse(
              '$baseUrl$apiV1/paper/trades/open?user_id=$userId'))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'trades': [], 'count': 0};
    }
  }

  Future<Map<String, dynamic>> fetchPaperTradeHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(
              '$baseUrl$apiV1/paper/trades/history?user_id=$userId&limit=$limit'))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'trades': [], 'count': 0};
    }
  }

  Future<Map<String, dynamic>> fetchPaperPerformance(
      {required String userId}) async {
    try {
      final response = await _client
          .get(Uri.parse(
              '$baseUrl$apiV1/paper/performance?user_id=$userId'))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      return {'total_trades': 0, 'win_rate': 0.0, 'total_pnl': 0.0};
    }
  }

  // ── Public accessors ──────────────────────────────────────────────────────
  Future<Map<String, String>> authHeaders() => _buildHeaders();
  String get instanceBaseUrl => ApiService.baseUrl;

  void dispose() => _client.close();
}