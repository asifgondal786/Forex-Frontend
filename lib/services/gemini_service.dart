// lib/services/gemini_service.dart
//
// SECURITY FIX: Gemini API key removed from Flutter client.
// All AI requests now proxy through the FastAPI backend.
// The key lives in Railway environment variables only.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  static const String _backendBaseUrl =
      'https://forex-backend-production-bc44.up.railway.app';
  static const String _chatEndpoint = '$_backendBaseUrl/api/ai/chat';

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

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
      final body = jsonEncode({
        'messages': messages,
        if (systemPrompt != null) 'system_prompt': systemPrompt,
        'model': model,
      });

      final response = await http
          .post(
            Uri.parse(_chatEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Handle both direct response and wrapped envelope {"data": {"content": ...}}
        final inner = data['data'] ?? data;
        return (inner as Map<String, dynamic>)['content'] as String? ?? '';
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
