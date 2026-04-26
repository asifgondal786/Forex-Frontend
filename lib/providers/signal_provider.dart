import 'package:flutter/foundation.dart';
import '../core/models/app_models.dart';
import '../services/api_service.dart';

class SignalProvider extends ChangeNotifier {
  final ApiService _api;

  List<SignalData> _signals = [];
  bool isGenerating = false;
  DateTime? lastGenerated;
  String? error;

  SignalProvider(this._api);

  List<SignalData> get signals => _signals;

  SignalData? signalFor(String pair) {
    try {
      return _signals.firstWhere((s) => s.pair == pair);
    } catch (_) {
      return null;
    }
  }

  Future<void> generateSignals({String? pair}) async {
    try {
      isGenerating = true;
      error = null;
      notifyListeners();
      final raw = await _api.fetchLiveSignals(
        pairs: pair != null ? [pair.replaceAll('/', '')] : [],
      );
      _signals = raw.map((j) => SignalData.fromJson(j)).toList();
      lastGenerated = DateTime.now();
    } catch (e) {
      error = e.toString();
      debugPrint('SignalProvider.generateSignals error: $e');
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }
}

