import 'package:flutter/material.dart';

class ModeProvider extends ChangeNotifier {
  bool _isExpertMode = false;
  bool get isExpertMode => _isExpertMode;
  bool get loaded => true;

  void toggle() {
    _isExpertMode = !_isExpertMode;
    notifyListeners();
  }
}

