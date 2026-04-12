import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../app_shell.dart';
import '../embodied_agent/embodied_agent_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/header_provider.dart';
import '../../providers/mode_provider.dart';
import 'package:forex_companion/features/auth/login_screen.dart';
import 'verification_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _didFetch = false;
  static const bool _requirePhoneVerification = bool.fromEnvironment(
    'REQUIRE_PHONE_VERIFICATION',
    defaultValue: false,
  );
  static const bool _skipAuthGate =
      bool.fromEnvironment('SKIP_AUTH_GATE', defaultValue: false);
  static const String _devUserId =
      String.fromEnvironment('DEV_USER_ID', defaultValue: '');

  bool get _firebaseAuthReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _fetchAfterBuild(BuildContext context) {
    if (_didFetch) return;
    _didFetch = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaskProvider>().fetchTasks();
      context.read<UserProvider>().fetchUser();
      context.read<HeaderProvider>().fetchHeader();
    });
  }

  void _goToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void _goAfterLogin(BuildContext context) {
    final modeProvider = context.read<ModeProvider>();
    final target = modeProvider.hasChosen
        ? const AppShell()
        : const OnboardingScreen();
    _goToScreen(context, target);
  }

  @override
  Widget build(BuildContext context) {
    // ── Dev shortcut (debug only) ──────────────────────────────────────────
    if (_skipAuthGate && kDebugMode) {
      if (_devUserId.isNotEmpty) {
        _fetchAfterBuild(context);
      }
      return const EmbodiedAgentScreen();
    }

    if (!_firebaseAuthReady) {
      _didFetch = false;
      return LoginScreen(onLoginSuccess: () => _goAfterLogin(context));
    }

    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          _didFetch = false;
          return LoginScreen(onLoginSuccess: () => _goAfterLogin(context));
        }

        final needsEmail = !(user.emailVerified);
        final needsPhone =
            _requirePhoneVerification && ((user.phoneNumber ?? '').isEmpty);
        if (needsEmail || needsPhone) {
          _didFetch = false;
          return const VerificationScreen();
        }

        _fetchAfterBuild(context);

        // ── Mode routing ───────────────────────────────────────────────────
        // Wait until ModeProvider has loaded from SharedPreferences
        final modeProvider = context.watch<ModeProvider>();
        if (!modeProvider.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // First-time user → show onboarding mode selector
        if (!modeProvider.hasChosen) {
          return const OnboardingScreen();
        }

        // Returning user → go straight to the main dashboard shell
        return const AppShell();
      },
    );
  }
}
