import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app_shell.dart';
import 'package:forex_companion/features/admin/user_admin_dashboard_screen.dart';
import '../features/ai_chat/ai_chat_screen.dart';
import '../features/auth/auth_entry_screen.dart';
import 'package:forex_companion/features/auth/login_screen.dart';
import '../features/auth/password_reset_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/verification_screen.dart';
import '../features/charts/chart_screen.dart';
import '../features/custom_setup/custom_setup_screen.dart';
import '../features/embodied_agent/embodied_agent_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_mode_preview_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/paper_trading/paper_trading_screen.dart';
import '../features/risk/risk_simulator_screen.dart';
import '../features/settings/security_center_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/task_creation/task_creation_screen.dart';
import '../features/task_history/task_history_screen.dart';
import '../providers/mode_provider.dart';

class AppRoutes {
  static const String root = '/';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String onboarding = '/onboarding';
  static const String onboardingPreviewBase = '/onboarding/preview';
  static const String createTask = '/create-task';
  static const String taskHistory = '/task-history';
  static const String aiChat = '/ai-chat';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String customSetup = '/custom-setup';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verify = '/verify';
  static const String reset = '/reset';
  static const String profile = '/profile';
  static const String security = '/security';
  static const String help = '/help';
  static const String charts = '/charts';
  static const String risk = '/risk';
  static const String paperTrading = '/paper-trading';
  static const String copilot = '/copilot';

  static String onboardingPreview(AppMode mode) =>
      '$onboardingPreviewBase/${mode.key}';

  static final Map<String, WidgetBuilder> routes = {
    root: (_) => const AuthEntryScreen(),
    login: (_) => LoginScreen(onLoginSuccess: () {}),
    signup: (_) => const SignupScreen(),
    verify: (_) => const VerificationScreen(),
    reset: (_) => const PasswordResetScreen(),
    home: (_) => const _ProtectedRoute(child: AppShell()),
    dashboard: (_) => const _ProtectedRoute(child: AppShell()),
    onboarding: (_) => const _ProtectedRoute(child: OnboardingScreen()),
    createTask: (_) => const _ProtectedRoute(child: TaskCreationScreen()),
    taskHistory: (_) => const _ProtectedRoute(child: TaskHistoryScreen()),
    aiChat: (_) => const _ProtectedRoute(child: AiChatScreen()),
    notifications: (_) => const _ProtectedRoute(child: NotificationsScreen()),
    settings: (_) => const _ProtectedRoute(child: SettingsScreen()),
    customSetup: (_) => const _ProtectedRoute(child: CustomSetupScreen()),
    profile: (_) => const _ProtectedRoute(child: UserAdminDashboardScreen()),
    security: (_) => const _ProtectedRoute(child: SecurityCenterScreen()),
    charts: (_) => const _ProtectedRoute(child: ChartScreen()),
    risk: (_) => const _ProtectedRoute(child: RiskSimulatorScreen()),
    '/chart': (_) => const ChartScreen(),
    paperTrading: (_) => const _ProtectedRoute(child: PaperTradingScreen()),
    copilot: (_) => const _ProtectedRoute(child: EmbodiedAgentScreen()),
    help: (_) => const _ProtectedRoute(
        child: PlaceholderScreen(title: 'Help & Support')),
  };

  static Map<String, WidgetBuilder> get materialRoutes =>
      Map<String, WidgetBuilder>.of(routes)..remove(root);

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final previewMode = _previewModeFromSettings(settings);
    if (previewMode == null) {
      return null;
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => _ProtectedRoute(
        child: OnboardingModePreviewScreen(mode: previewMode),
      ),
    );
  }

  static AppMode? _previewModeFromSettings(RouteSettings settings) {
    final argument = settings.arguments;
    if (argument is AppMode) {
      return argument;
    }

    final name = settings.name;
    if (name == null || !name.startsWith('$onboardingPreviewBase/')) {
      return null;
    }

    final modeKey = name.substring(onboardingPreviewBase.length + 1);
    for (final mode in AppMode.values) {
      if (mode.key == modeKey) {
        return mode;
      }
    }
    return null;
  }
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

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '$title Page',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This page is under construction',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
