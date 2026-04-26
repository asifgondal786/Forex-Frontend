class SignalData {
  final String pair;
  final String action;
  final double confidence;
  final String reasoning;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit;
  final DateTime timestamp;

  SignalData({
    required this.pair,
    required this.action,
    required this.confidence,
    required this.reasoning,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.timestamp,
  });

  factory SignalData.fromJson(Map<String, dynamic> json) {
    return SignalData(
      pair: json['pair']?.toString() ?? '',
      action: json['action']?.toString() ?? 'HOLD',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning']?.toString() ?? '',
      entryPrice: (json['entry_price'] as num?)?.toDouble() ?? 0.0,
      stopLoss: (json['stop_loss'] as num?)?.toDouble() ?? 0.0,
      takeProfit: (json['take_profit'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
