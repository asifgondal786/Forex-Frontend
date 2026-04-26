import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../core/models/user.dart' as app_user;

class FirebaseService {
  final FirebaseFirestore? _firestore;
  final firebase_auth.FirebaseAuth? _auth;

  FirebaseService()
      : _firestore = _hasFirebaseApps ? FirebaseFirestore.instance : null,
        _auth = _hasFirebaseApps ? firebase_auth.FirebaseAuth.instance : null;

  static bool get _hasFirebaseApps => Firebase.apps.isNotEmpty;

  Future<app_user.User?> getCurrentUser() async {
    try {
      final u = _auth?.currentUser;
      if (u == null) return null;
      final doc = await _firestore?.collection('users').doc(u.uid).get();
      if (doc == null || !doc.exists) return null;
      final data = doc.data() ?? {};
      return app_user.User(
        id: u.uid,
        email: u.email ?? '',
        name: data['name'] ?? data['displayName'] ?? u.displayName ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        preferences: data['preferences'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('FirebaseService.getCurrentUser error: $e');
      return null;
    }
  }

  Future<void> saveUser(app_user.User user) async {
    try {
      await _firestore?.collection('users').doc(user.id).set({
        'email': user.email,
        'name': user.name,
        'preferences': user.preferences ?? {},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseService.saveUser error: $e');
    }
  }

  Future<firebase_auth.User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth?.signInWithEmailAndPassword(
          email: email, password: password);
      return cred?.user;
    } catch (e) {
      debugPrint('FirebaseService.signInWithEmail error: $e');
      rethrow;
    }
  }

  Future<firebase_auth.User?> signUpWithEmail(String email, String password) async {
    try {
      final cred = await _auth?.createUserWithEmailAndPassword(
          email: email, password: password);
      return cred?.user;
    } catch (e) {
      debugPrint('FirebaseService.signUpWithEmail error: $e');
      rethrow;
    }
  }

  Future<void> createUserDocument(app_user.User user) async {
    try {
      await _firestore?.collection('users').doc(user.id).set({
        'email': user.email,
        'name': user.name,
        'preferences': user.preferences ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseService.createUserDocument error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory([String? userId]) async {
    try {
      final uid = userId ?? _auth?.currentUser?.uid;
      if (uid == null) return [];
      final snap = await _firestore
          ?.collection('notifications')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap?.docs.map((d) => {'id': d.id, ...d.data()}).toList() ?? [];
    } catch (e) {
      debugPrint('FirebaseService.getNotificationHistory error: $e');
      return [];
    }
  }

  Future<void> clearNotificationHistory([String? userId]) async {
    try {
      final uid = userId ?? _auth?.currentUser?.uid;
      if (uid == null) return;
      final snap = await _firestore
          ?.collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();
      final batch = _firestore?.batch();
      snap?.docs.forEach((d) => batch?.delete(d.reference));
      await batch?.commit();
    } catch (e) {
      debugPrint('FirebaseService.clearNotificationHistory error: $e');
    }
  }

  Future<void> logTradeAction(Map<String, dynamic> tradeData) async {
    try {
      await _firestore?.collection('trade_log').add({
        ...tradeData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirebaseService.logTradeAction error: $e');
    }
  }
}
