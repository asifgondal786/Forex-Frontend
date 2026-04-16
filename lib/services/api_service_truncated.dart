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
  static const String apiV1  = '/api/v1';
  static const String apiV1b = '/v1/api';
  static const String apiV1c = '/v1';
  static const String _baseUrlFromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const Duration _timeout = Duration(seconds: 10);
  static const bool _allowDebugUserFallback = bool.fromEnvironment('ALLOW_DEBUG_USER_FALLBACK', defaultValue: true);
  
  final http.Client _client = http.Client();
  
  static String get baseUrl => 'http://127.0.0.1:8080';
  
  void test() {
    print('test');
  }
  
  Future<void> dispose() async {
    _client.close();
  }
}
