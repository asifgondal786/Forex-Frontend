import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../core/models/user.dart' as app_user;
import '../core/models/app_models.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebase;
  AuthStatus _status = AuthStatus.loading;
  app_user.User? _currentUser;
  String? error;

  AuthProvider(this._firebase);

  AuthStatus get status => _status;
  app_user.User? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> init() async {
    try {
      _currentUser = await _firebase.getCurrentUser();
      _status = _currentUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      debugPrint('AuthProvider.init error: $e');
    }
    notifyListeners();
  }

  void setUser(app_user.User user) {
    _currentUser = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
