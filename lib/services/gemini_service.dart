// lib/services/gemini_service.dart
//
// SECURITY FIX: Gemini API key removed from Flutter client.
// All AI requests proxy through FastAPI backend with Firebase Auth.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeminiService {
  static const String _backendBaseUrl =
      'https://forex-backend-production-bc44.up.railway.app';
  static const String _chatEndpoint = '$_backendBaseUrl/api/ai/chat';

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Get current Firebase ID token (auto-refreshes if expired)
  Future<String?> _getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      debugPrint('GeminiService: failed to get ID token: $e');
      return null;
    }
  }

  Future<String> sendMessage(String userMessage) async {
    return _chat(messages: [
      {'role': 'user', 'content': userMessage},
    ]);
  }

  Future<String> sendConversation(List<Map<String, String>> history) async {
    return _chat(messages: history);
  }

  Future<String> analyzeForexPair({
    required String pair,
    required String timeframe,
    Map<String, dynamic>? indicators,
  }) async {
    final indicatorText = indicators != null
        ? indicators.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : 'No indicators provided';

    final prompt = '''
You are an expert Forex trading analyst. Analyse the following:
Currency Pair: $pair
Timeframe: $timeframe
Technical Indicators: $indicatorText

Provide a concise analysis covering:
1. Current trend direction
2. Key support and resistance levels
3. Trading signals or patterns observed
4. Risk assessment
5. Short-term price outlook

Keep the response practical and actionable.
''';
    return sendMessage(prompt);
  }

  Future<String> generateTaskPlan({
    required String goal,
    String? context,
  }) async {
    final prompt = '''
You are a Forex trading assistant. Create a structured task plan for:
Goal: $goal
${context != null ? 'Context: $context' : ''}

Provide clear, numbered steps with realistic timeframes.
''';
    return sendMessage(prompt);
  }

  Future<String> _chat({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    String model = 'gemini-2.0-flash',
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw GeminiServiceException(
          'You must be signed in to use AI features.',
        );
      }

      final body = jsonEncode({
        'messages': messages,
        if (systemPrompt != null) 'system_prompt': systemPrompt,
        'model': model,
      });

      final response = await http
          .post(
            Uri.parse(_chatEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Handle API envelope: {"data": {"content": "..."}, "status": "success"}
        final inner = data['data'] ?? data;
        return (inner as Map<String, dynamic>)['content'] as String? ?? '';
      } else if (response.statusCode == 401) {
        throw GeminiServiceException(
          'Session expired. Please sign in again.',
        );
      } else if (response.statusCode == 503) {
        throw GeminiServiceException(
          'AI service is temporarily unavailable. Please try again later.',
        );
      } else {
        debugPrint('AI proxy error ${response.statusCode}: ${response.body}');
        throw GeminiServiceException(
          'AI request failed (${response.statusCode}). Please try again.',
        );
      }
    } on GeminiServiceException {
      rethrow;
    } catch (e) {
      debugPrint('GeminiService network error: $e');
      throw GeminiServiceException(
        'Could not connect to AI service. Check your internet connection.',
      );
    }
  }
}

class GeminiServiceException implements Exception {
  final String message;
  const GeminiServiceException(this.message);

  @override
  String toString() => 'GeminiServiceException: $message';
}
