import 'package:flutter/material.dart';

class BrokerProvider extends ChangeNotifier {
  String? _connectedBroker;
  bool _isConnecting = false;

  String? get connectedBroker => _connectedBroker;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _connectedBroker != null;

  Future<void> connect(String broker) async {
    _isConnecting = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _connectedBroker = broker;
    _isConnecting = false;
    notifyListeners();
  }

  void disconnect() {
    _connectedBroker = null;
    notifyListeners();
  }
}
