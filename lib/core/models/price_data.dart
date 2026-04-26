class PriceData {
  final String pair;
  final double bid;
  final double ask;
  final double mid;
  final double spread;
  final DateTime timestamp;

  PriceData({
    required this.pair,
    required this.bid,
    required this.ask,
    required this.mid,
    required this.spread,
    required this.timestamp,
  });

  factory PriceData.fromJson(Map<String, dynamic> json) {
    final bid = (json['bid'] as num?)?.toDouble() ?? 0.0;
    final ask = (json['ask'] as num?)?.toDouble() ?? 0.0;
    return PriceData(
      pair: json['pair']?.toString() ?? '',
      bid: bid,
      ask: ask,
      mid: (bid + ask) / 2,
      spread: ask - bid,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
