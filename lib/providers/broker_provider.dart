import 'package:flutter/foundation.dart';

class BrokerAccount {
  final String id;
  final String name;
  final String broker;
  final String status; // 'connected' | 'disconnected'
  final bool isLive;

  const BrokerAccount({
    required this.id,
    required this.name,
    required this.broker,
    required this.status,
    required this.isLive,
  });

  bool get connected => status == 'connected';
  String get displayBalance => '0.00';
  String get currency => 'USD';
  String get displayName => '$broker — $name';
}

class BrokerProvider extends ChangeNotifier {
  BrokerAccount? _selectedAccount;
  bool isLoading = false;
  String? lastError;

  BrokerAccount? get selectedAccount => _selectedAccount;
  bool get isConnected => _selectedAccount?.connected ?? false;
  String get modeLabel => _selectedAccount?.isLive == true ? 'LIVE' : 'DEMO';

  Future<void> connect(String broker, String accountId, String name,
      {bool isLive = false}) async {
    try {
      isLoading = true;
      lastError = null;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1));
      _selectedAccount = BrokerAccount(
        id: accountId,
        name: name,
        broker: broker,
        status: 'connected',
        isLive: isLive,
      );
    } catch (e) {
      lastError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnect(String accountId) async {
    _selectedAccount = null;
    notifyListeners();
  }

  Future<void> loadConnections() async {
    // Placeholder — refresh from backend if needed
    notifyListeners();
  }

    void disconnect0() {
    _selectedAccount = null;
    notifyListeners();
  }
}




