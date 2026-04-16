import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app_shell.dart';
import '../features/ai_chat/ai_chat_screen.dart';
import '../features/auth/auth_entry_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/password_reset_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/verification_screen.dart';
import '../features/charts/chart_screen.dart';
import '../features/settings/security_center_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRoutes {
  static const String root = '/';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String aiChat = '/ai-chat';
  static const String settings = '/settings';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verify = '/verify';
  static const String reset = '/reset';
  static const String security = '/security';
  static const String charts = '/charts';

  static final Map<String, WidgetBuilder> routes = {
    root: (_) => const AuthEntryScreen(),
    login: (_) => LoginScreen(onLoginSuccess: () {}),
    signup: (_) => const SignupScreen(),
    verify: (_) => const VerificationScreen(),
    reset: (_) => const PasswordResetScreen(),
    home: (_) => const _ProtectedRoute(child: AppShell()),
    dashboard: (_) => const _ProtectedRoute(child: AppShell()),
    aiChat: (_) => const _ProtectedRoute(child: AiChatScreen()),
    settings: (_) => const _ProtectedRoute(child: SettingsScreen()),
    security: (_) => const _ProtectedRoute(child: SecurityCenterScreen()),
    charts: (_) => const _ProtectedRoute(child: ChartScreen()),
    '/chart': (_) => const ChartScreen(),
  };
}

class _ProtectedRoute extends StatelessWidget {
  final Widget child;

  const _ProtectedRoute({required this.child});

  bool get _firebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_firebaseReady) {
      return LoginScreen(onLoginSuccess: () {});
    }

    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return LoginScreen(onLoginSuccess: () {});
        }

        return child;
      },
    );
  }
}

