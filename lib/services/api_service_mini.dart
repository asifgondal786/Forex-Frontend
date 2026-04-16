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
  
  void test() {
    print('test');
  }
}
