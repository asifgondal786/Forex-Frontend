import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../core/models/user.dart' as app_user;
import '../core/models/app_models.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebase;

  AuthStatus _status = AuthStatus.loading;
  app_user.User? _currentUser;
  String? error;

  // ── Trial & plan state ────────────────────────────────────────────────────
  bool _isTrialExpired = false;
  int _trialDaysLeft = 10;
  bool _isSubscribed = false;

  // ── Firestore real-time listener ──────────────────────────────────────────
  // Holds the cancel function so we can unsubscribe on sign-out
  StreamSubscription? _userDocListener;

  AuthProvider(this._firebase);

  // ── Getters ───────────────────────────────────────────────────────────────
  AuthStatus get status        => _status;
  app_user.User? get currentUser => _currentUser;
  bool get isAuthenticated     => _status == AuthStatus.authenticated;
  bool get isTrialExpired      => _isTrialExpired;
  bool get isSubscribed        => _isSubscribed;
  int  get trialDaysLeft       => _trialDaysLeft;

  /// True when the user can access all features.
  /// Either they are subscribed OR their trial is still active.
  bool get hasFullAccess => _isSubscribed || !_isTrialExpired;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      _currentUser = await _firebase.getCurrentUser();
      _status = _currentUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;

      if (_currentUser != null) {
        await _startUserDocListener(_currentUser!.id);
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      debugPrint('AuthProvider.init error: $e');
    }
    notifyListeners();
  }

  // ── Real-time Firestore listener ──────────────────────────────────────────
  /// Listens to the user document in Firestore for plan changes.
  /// This means the moment you activate a subscription from your admin panel
  /// or via webhook, the app updates instantly without requiring a restart.
  Future<void> _startUserDocListener(String userId) async {
    _userDocListener?.cancel(); // cancel any existing listener

    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);

    _userDocListener = docRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data();
        if (data == null) return;
        _applyPlanData(data);
        notifyListeners();
      },
      onError: (e) => debugPrint('AuthProvider user doc listener error: $e'),
    );
  }

  /// Parses plan fields from a Firestore user document.
  void _applyPlanData(Map<String, dynamic> data) {
    // Subscription status
    _isSubscribed = data['isSubscribed'] as bool? ?? false;

    // Trial expiry
    final trialStartRaw = data['trialStartDate'];
    if (trialStartRaw != null) {
      DateTime trialStart;
      if (trialStartRaw is Timestamp) {
        trialStart = trialStartRaw.toDate();
      } else if (trialStartRaw is String) {
        trialStart = DateTime.tryParse(trialStartRaw) ?? DateTime.now();
      } else {
        trialStart = DateTime.now();
      }

      final trialEnd = trialStart.add(const Duration(days: 10));
      final now = DateTime.now();
      _isTrialExpired = now.isAfter(trialEnd);
      final remaining = trialEnd.difference(now);
      _trialDaysLeft = _isTrialExpired ? 0 : remaining.inDays.clamp(0, 10);
    } else {
      // No trial start date recorded — treat as new user, trial not started
      _isTrialExpired = false;
      _trialDaysLeft = 10;
    }
  }

  // ── Manual refresh ────────────────────────────────────────────────────────
  /// Call this after a successful payment to force-refresh plan state.
  /// The Firestore listener will usually catch it automatically, but this
  /// provides an explicit refresh for the subscription screen success flow.
  Future<void> refreshUserPlan() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.id)
          .get();
      if (doc.exists && doc.data() != null) {
        _applyPlanData(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider.refreshUserPlan error: $e');
    }
  }

  // ── Set user ──────────────────────────────────────────────────────────────
  void setUser(app_user.User user) {
    _currentUser = user;
    _status = AuthStatus.authenticated;
    _startUserDocListener(user.id);
    notifyListeners();
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _userDocListener?.cancel(); // cancel Firestore listener
    _userDocListener = null;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _isTrialExpired = false;
    _isSubscribed = false;
    _trialDaysLeft = 10;
    notifyListeners();
  }
}
