// lib/core/models/app_models.dart
// Single source of truth for shared models

enum AuthStatus { loading, authenticated, unauthenticated, unknown }
enum SignalAction { buy, sell, hold }

// ── PriceData ─────────────────────────────────────────────────────────────────
class PriceData {
  final String pair;
  final double bid;
  final double ask;
  final double change;
  final double changePercent;
  final DateTime timestamp;

  const PriceData({
    required this.pair,
    required this.bid,
    required this.ask,
    required this.change,
    required this.changePercent,
    required this.timestamp,
  });

  bool get isUp => change >= 0;
  String get displayBid => bid.toStringAsFixed(pair.contains('JPY') ? 3 : 5);
  String get displayAsk => ask.toStringAsFixed(pair.contains('JPY') ? 3 : 5);

  factory PriceData.fromJson(Map<String, dynamic> j) => PriceData(
    pair: (j['pair'] ?? j['symbol'] ?? '').toString(),
    bid: (j['bid'] ?? j['price'] ?? 0).toDouble(),
    ask: (j['ask'] ?? j['price'] ?? 0).toDouble(),
    change: (j['change'] ?? 0).toDouble(),
    changePercent: (j['change_percent'] ?? j['changePercent'] ?? 0).toDouble(),
    timestamp: DateTime.tryParse(j['timestamp']?.toString() ?? '') ?? DateTime.now(),
  );
}

// ── SignalData ────────────────────────────────────────────────────────────────
class SignalData {
  final String pair;
  final String action;
  final double confidence;
  final double? entryPrice;
  final double? stopLoss;
  final double? takeProfit;
  final String reasoning;
  final DateTime timestamp;

  const SignalData({
    required this.pair,
    required this.action,
    required this.confidence,
    this.entryPrice,
    this.stopLoss,
    this.takeProfit,
    this.reasoning = '',
    required this.timestamp,
  });

  double? get entry => entryPrice;

  factory SignalData.fromJson(Map<String, dynamic> j) => SignalData(
    pair: (j['pair'] ?? j['symbol'] ?? '').toString(),
    action: (j['action'] ?? j['signal'] ?? 'hold').toString(),
    confidence: (j['confidence'] ?? 0).toDouble(),
    entryPrice: j['entry_price'] != null ? (j['entry_price']).toDouble() : null,
    stopLoss: j['stop_loss'] != null ? (j['stop_loss']).toDouble() : null,
    takeProfit: j['take_profit'] != null ? (j['take_profit']).toDouble() : null,
    reasoning: j['reasoning']?.toString() ?? j['analysis']?.toString() ?? '',
    timestamp: DateTime.tryParse(j['timestamp']?.toString() ?? '') ?? DateTime.now(),
  );
}


