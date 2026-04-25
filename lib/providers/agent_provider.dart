import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum AgentMode { off, semiAuto, fullAuto }

class PendingTrade {
  final String id;
  final String pair;
  final String direction;
  final double confidence;
  final double? entry;
  final double? stopLoss;
  final double? takeProfit;
  final String reasoning;

  const PendingTrade({
    required this.id,
    required this.pair,
    required this.direction,
    required this.confidence,
    this.entry,
    this.stopLoss,
    this.takeProfit,
    required this.reasoning,
  });

  factory PendingTrade.fromJson(Map<String, dynamic> j) => PendingTrade(
        id: j['id'] as String? ?? '',
        pair: j['pair'] as String? ?? '',
        direction: (j['direction'] as String? ?? 'BUY').toUpperCase(),
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.5,
        entry: (j['entry'] as num?)?.toDouble(),
        stopLoss: (j['stop_loss'] as num?)?.toDouble(),
        takeProfit: (j['take_profit'] as num?)?.toDouble(),
        reasoning: j['reasoning'] as String? ?? '',
      );
}

class ActiveTrade {
  final String id;
  final String pair;
  final String direction;
  final double lotSize;
  final double openPrice;
  final double? currentPrice;
  final double pnl;
  final DateTime openedAt;

  const ActiveTrade({
    required this.id,
    required this.pair,
    required this.direction,
    required this.lotSize,
    required this.openPrice,
    this.currentPrice,
    required this.pnl,
    required this.openedAt,
  });

  factory ActiveTrade.fromJson(Map<String, dynamic> j) => ActiveTrade(
        id: j['id'] as String? ?? '',
        pair: j['pair'] as String? ?? '',
        direction: (j['direction'] as String? ?? 'BUY').toUpperCase(),
        lotSize: (j['lot_size'] as num?)?.toDouble() ?? 0.01,
        openPrice: (j['open_price'] as num?)?.toDouble() ?? 0,
        currentPrice: (j['current_price'] as num?)?.toDouble(),
        pnl: (j['pnl'] as num?)?.toDouble() ?? 0,
        openedAt: j['opened_at'] != null
            ? DateTime.tryParse(j['opened_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class AgentProvider extends ChangeNotifier {
  final ApiService _api;

  AgentMode _mode = AgentMode.off;
  bool _isLoading = false;
  bool _isKilling = false;
  List<PendingTrade> _pendingTrades = [];
  List<ActiveTrade> _activeTrades = [];
  double _totalPnl = 0;
  String? _error;
  Timer? _pollTimer;

  AgentMode get mode => _mode;
  bool get isLoading => _isLoading;
  bool get isKilling => _isKilling;
  bool get isActive => _mode != AgentMode.off;
  List<PendingTrade> get pendingTrades => _pendingTrades;
  List<ActiveTrade> get activeTrades => _activeTrades;
  double get totalPnl => _totalPnl;
  String? get error => _error;

  String get modeLabel {
    switch (_mode) {
      case AgentMode.off: return 'OFF';
      case AgentMode.semiAuto: return 'SEMI-AUTO';
      case AgentMode.fullAuto: return 'FULL-AUTO';
    }
  }

  AgentProvider(this._api) {
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final data = await _api.fetchAgentStatus();
      final modeStr = data['mode'] as String? ?? 'off';
      _mode = modeStr == 'full_auto'
          ? AgentMode.fullAuto
          : modeStr == 'semi_auto'
              ? AgentMode.semiAuto
              : AgentMode.off;

      final pending = data['pending_trades'] as List<dynamic>? ?? [];
      _pendingTrades = pending
          .whereType<Map<String, dynamic>>()
          .map((j) => PendingTrade.fromJson(j))
          .toList();

      final active = data['active_trades'] as List<dynamic>? ?? [];
      _activeTrades = active
          .whereType<Map<String, dynamic>>()
          .map((j) => ActiveTrade.fromJson(j))
          .toList();

      _totalPnl = (data['total_pnl'] as num?)?.toDouble() ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setMode(AgentMode newMode, {Map<String, dynamic>? params}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (newMode == AgentMode.off) {
        await _api.stopAgent();
        _pendingTrades = [];
        _pollTimer?.cancel();
      } else {
        final modeStr = newMode == AgentMode.fullAuto ? 'full_auto' : 'semi_auto';
        await _api.startAgent({'mode': modeStr, ...?params});
        _startPolling();
      }
      _mode = newMode;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> killAgent() async {
    _isKilling = true;
    notifyListeners();
    try {
      await _api.killAgent();
      _mode = AgentMode.off;
      _pendingTrades = [];
      _activeTrades = [];
      _pollTimer?.cancel();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isKilling = false;
      notifyListeners();
    }
  }

  Future<void> approveTrade(String tradeId) async {
    try {
      await _api.approveTrade(tradeId);
      _pendingTrades.removeWhere((t) => t.id == tradeId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectTrade(String tradeId) async {
    try {
      await _api.rejectTrade(tradeId);
      _pendingTrades.removeWhere((t) => t.id == tradeId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}