import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class GeminiService {
  // It's strongly recommended to load the API key from a secure source,
  // such as environment variables, rather than hardcoding it.
  // Use --dart-define=GEMINI_API_KEY=YOUR_API_KEY
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  late final GenerativeModel? _model;
  late final GenerativeModel? _chatModel;
  
  bool get isAvailable => _apiKey.isNotEmpty;

  GeminiService() {
    if (_apiKey.isEmpty) {
      _model = null;
      _chatModel = null;
      debugPrint('⚠️ GEMINI_API_KEY not set. AI features disabled.');
      return;
    }
    
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );

    _chatModel = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.9,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
  }

  // Generate trading task suggestions based on user input
  Future<Map<String, dynamic>> generateTaskSuggestion(String userInput) async {
    // If Gemini is not available, return default suggestion based on user input
    if (!isAvailable) {
      debugPrint('⚠️ Gemini not available, returning default suggestion');
      return {
        'title': userInput.length > 50 ? userInput.substring(0, 50) + '...' : userInput,
        'description': 'AI-enhanced description would appear here if Gemini API is configured.\n\nUser Input: $userInput',
        'priority': 'medium',
        'estimatedDuration': '2 hours',
        'steps': [
          'Step 1: Analyze market conditions',
          'Step 2: Generate trading signals',
          'Step 3: Execute trading strategy'
        ],
        'riskLevel': 'medium',
        'recommendation': 'Task created. Enable Gemini API for AI-powered suggestions.'
      };
    }

    final prompt = '''
You are a Forex trading AI assistant. Based on the user's request, generate a structured trading task.

User Request: "$userInput"

Generate a JSON response with:
{
  "title": "Clear, concise task title",
  "description": "Detailed description of what this task will do",
  "priority": "high|medium|low",
  "estimatedDuration": "Estimated time to complete (e.g., '2 hours')",
  "steps": [
    "Step 1: Action to take",
    "Step 2: Action to take",
    "Step 3: Action to take"
  ],
  "riskLevel": "low|medium|high",
  "recommendation": "Brief AI recommendation"
}

Focus on forex trading tasks like: market analysis, trend detection, signal generation, risk assessment, etc.
''';

    try {
      final response = await _model?.generateContent([Content.text(prompt)]);
      if (response == null) throw Exception('No response from Gemini');
      
      final text = response.text ?? '';
      
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return json.decode(jsonMatch.group(0)!);
      }
      
      throw Exception('Failed to parse AI response');
    } catch (e) {
      throw Exception('Gemini AI Error: $e');
    }
  }

  // Analyze forex market data and provide insights
  Future<String> analyzeMarketData(Map<String, dynamic> marketData) async {
    final prompt = '''
You are a Forex trading expert. Analyze this market data and provide actionable insights:

Market Data:
${json.encode(marketData)}

Provide:
1. Current market trend
2. Key support/resistance levels
3. Trading opportunities
4. Risk factors
5. Recommended actions

Keep response concise and actionable.
''';

    try {
      final response = await _model?.generateContent([Content.text(prompt)]);
      if (response == null) throw Exception('Gemini not available');
      return response.text ?? 'No analysis available';
    } catch (e) {
      throw Exception('Market analysis failed: $e');
    }
  }

  // Generate trading strategy
  Future<String> generateTradingStrategy({
    required String currencyPair,
    required String timeframe,
    required String riskTolerance,
  }) async {
    final prompt = '''
Create a Forex trading strategy for:
- Currency Pair: $currencyPair
- Timeframe: $timeframe
- Risk Tolerance: $riskTolerance

Provide:
1. Entry/exit criteria
2. Stop loss and take profit levels
3. Position sizing recommendations
4. Key indicators to monitor
5. Risk management rules

Format as clear, actionable steps.
''';

    try {
      final response = await _model?.generateContent([Content.text(prompt)]);
      if (response == null) throw Exception('Gemini not available');
      return response.text ?? 'Strategy generation failed';
    } catch (e) {
      throw Exception('Strategy generation failed: $e');
    }
  }

  // Chat interface for forex questions
  Future<String> chat(String message, {List<String>? context}) async {
    // If Gemini is not available, return placeholder response
    if (!isAvailable) {
      debugPrint('⚠️ Gemini not available for chat');
      return 'Hello! I\'m a Forex trading AI assistant. To use AI features, please configure your Gemini API key.\n\nYour message: "$message"';
    }

    String fullPrompt = '''
You are Forex Companion AI, an expert forex trading assistant. 
You help users with market analysis, trading strategies, and risk management.
Be concise, professional, and actionable in your responses.
''';

    if (context != null && context.isNotEmpty) {
      fullPrompt += '\n\nConversation context:\n${context.join('\n')}';
    }

    fullPrompt += '\n\nUser: $message\n\nAssistant:';

    try {
      final response = await _chatModel!.generateContent([Content.text(fullPrompt)]);
      return response.text ?? 'I apologize, I could not generate a response.';
    } catch (e) {
      throw Exception('Chat failed: $e');
    }
  }

  // Validate and enhance task description
  Future<String> enhanceTaskDescription(String description) async {
    if (!isAvailable) {
      return description; // Return original if Gemini not available
    }

    final prompt = '''
Enhance this forex trading task description to be more specific and actionable:

Original: "$description"

Improved version should:
- Be clear and specific
- Include measurable goals
- Mention relevant indicators/tools
- Specify timeframe
- Include risk considerations

Return only the enhanced description.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? description;
    } catch (e) {
      return description; // Return original on error
    }
  }

  // Generate risk assessment
  Future<Map<String, dynamic>> assessRisk(String taskDescription) async {
    if (!isAvailable) {
      return {
        'riskLevel': 'medium',
        'riskFactors': ['Unable to assess without Gemini API'],
        'mitigation': ['Enable Gemini API for risk assessment'],
        'confidence': 0.0
      };
    }

    final prompt = '''
Assess the risk level of this forex trading task:

Task: "$taskDescription"

Return JSON:
{
  "riskLevel": "low|medium|high",
  "riskFactors": ["factor 1", "factor 2"],
  "mitigation": ["strategy 1", "strategy 2"],
  "confidence": 0.0-1.0
}
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return json.decode(jsonMatch.group(0)!);
      }
      throw Exception('Failed to parse risk assessment');
    } catch (e) {
      return {
        'riskLevel': 'medium',
        'riskFactors': ['Unable to assess'],
        'mitigation': ['Proceed with caution'],
        'confidence': 0.5,
      };
    }
  }
}