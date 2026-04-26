import 'package:flutter/foundation.dart';
import '../core/models/app_models.dart';
import '../services/api_service.dart';

class MarketProvider extends ChangeNotifier {
  final ApiService _api;

  final List<String> pairs = [
    'EUR/USD', 'GBP/USD', 'USD/JPY', 'USD/CHF',
    'AUD/USD', 'USD/CAD', 'NZD/USD', 'EUR/GBP',
  ];

  Map<String, PriceData> prices = {};
  String selectedPair = 'EUR/USD';
  bool isLoading = false;
  String? error;

  MarketProvider(this._api);

  void selectPair(String pair) {
    selectedPair = pair;
    notifyListeners();
  }

  Future<void> fetchPrices() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final raw = await _api.fetchMarketPrices(
        pairs: pairs.map((p) => p.replaceAll('/', '')).toList(),
      );
      for (final j in raw) {
        final pd = PriceData.fromJson(j);
        prices[pd.pair] = pd;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('MarketProvider.fetchPrices error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
