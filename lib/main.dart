import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// ── Shell & Auth ──────────────────────────────────────────────────────────────
import 'app_shell.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'routes/app_routes.dart';

// ── Core config (preserved from existing main.dart) ──────────────────────────
import 'core/config/firebase_config.dart';
import 'core/config/release_build_guard.dart';
import 'core/utils/runtime_url_resolver.dart';

// ── Services (preserved from existing main.dart) ──────────────────────────────
import 'services/api_service.dart';
import 'services/chart_service.dart';
import 'services/firebase_service.dart';
import 'services/live_updates_service.dart';

// ── Existing providers (preserved from existing main.dart) ────────────────────
import 'providers/mode_provider.dart';
import 'providers/app_shell_provider.dart';
import 'providers/quick_actions_provider.dart';
import 'providers/custom_setup_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'providers/header_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/account_connection_provider.dart';
import 'providers/agent_orchestrator_provider.dart';
import 'providers/market_watch_provider.dart';
import 'providers/trade_signals_provider.dart';
import 'providers/chart_provider.dart';
import 'providers/news_events_provider.dart';
import 'providers/risk_provider.dart';
import 'providers/paper_trading_provider.dart';

// ── New providers (from redesign files) ───────────────────────────────────────
import 'providers/portfolio_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/beginner_mode_provider.dart';
import 'providers/automation_provider.dart';
import 'providers/social_provider.dart';
import 'providers/trade_execution.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────
import 'helpers/mock_data_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feature flags  (unchanged from existing main.dart)
// ─────────────────────────────────────────────────────────────────────────────

/// Toggle Firebase Auth / Storage / etc.
const bool useFirebaseAuth = true;

/// Use anonymous sign-in so API requests have a Firebase ID token in dev.
const bool useAnonymousAuth = false;

/// Toggle Firestore-backed tasks on the client (backend is source of truth).
const bool useFirestoreTasks = false;

/// Set to true for UI development without a backend.
const bool useMockData = false;

// ─────────────────────────────────────────────────────────────────────────────
// Boot-time URL validation  (preserved from existing main.dart)
// ─────────────────────────────────────────────────────────────────────────────

void _validateUrlConfigOnBoot() {
  if (kDebugMode) return;
  final apiBaseUrl = ApiService.baseUrl;
  assertSecureRuntimeUrl(
    apiBaseUrl,
    label: 'API_BASE_URL',
    allowHttpInRelease: false,
  );
  resolveAppWebUrl(
    const String.fromEnvironment('APP_WEB_URL', defaultValue: ''),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  ensureReleaseBuildConfig();
  WidgetsFlutterBinding.ensureInitialized();
  _validateUrlConfigOnBoot();

  // Phase 16 — chart service init
  await ChartService.init();

  bool firebaseReady = false;
  if (useFirebaseAuth) {
    try {
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatform,
      );
      firebaseReady = true;
      debugPrint('Firebase initialized successfully');
      debugPrint('Project: forexcompanion-e5a28');

      if (useAnonymousAuth) {
        try {
          final auth = firebase_auth.FirebaseAuth.instance;
          if (auth.currentUser == null) {
            await auth.signInAnonymously();
            debugPrint('Signed in anonymously');
          }
        } catch (e) {
          debugPrint('Anonymous sign-in failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      debugPrint('Falling back to API mode');
    }
  } else {
    debugPrint('Running in API-only mode (Firebase disabled)');
  }

  runApp(TajirApp(firebaseReady: firebaseReady));
}

// ─────────────────────────────────────────────────────────────────────────────
// Root app widget
// ─────────────────────────────────────────────────────────────────────────────

class TajirApp extends StatelessWidget {
  final bool firebaseReady;
  const TajirApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final firebaseService =
        (useFirebaseAuth && firebaseReady) ? FirebaseService() : null;

    return MultiProvider(
      providers: [
        // ── Services ────────────────────────────────────────────────────────
        Provider<ApiService>.value(value: apiService),
        if (firebaseService != null)
          Provider<FirebaseService>.value(value: firebaseService),
        Provider<LiveUpdatesService>(
          create: (_) => LiveUpdatesService(),
          dispose: (_, service) => service.dispose(),
        ),

        // ── Core / theme providers ──────────────────────────────────────────
        //    ThemeProvider drives light/dark toggle from settings.
        //    ModeProvider drives Beginner / Assisted / Semi / Full mode.
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ModeProvider()..load()),
        ChangeNotifierProvider(create: (_) => AppShellProvider()),

        // ── Beginner-mode provider (new — drives overlay & guardrails UI) ───
        ChangeNotifierProvider(create: (_) => BeginnerModeProvider()..load()),

        // ── Quick actions & custom setup ────────────────────────────────────
        ChangeNotifierProvider(create: (_) => QuickActionsProvider()..load()),
        ChangeNotifierProvider(create: (_) => CustomSetupProvider()),

        // ── Market data providers ───────────────────────────────────────────
        ChangeNotifierProvider(
          create: (ctx) =>
              MarketWatchProvider(apiService: ctx.read<ApiService>())..init(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ChartProvider(ctx.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              TradeSignalsProvider(ctx.read<ApiService>())..init(),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              NewsEventsProvider(ctx.read<ApiService>())..init(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => RiskProvider(ctx.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PaperTradingProvider(ctx.read<ApiService>()),
        ),

        // ── Portfolio provider (new — portfolio screen) ─────────────────────
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),

        // ── Notification provider (new — notification screen + badge) ───────
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // ── Automation provider (new — automation screen) ───────────────────
        ChangeNotifierProvider(create: (_) => AutomationProvider()),

        // ── Social trading provider (new — social screen) ───────────────────
        ChangeNotifierProvider(create: (_) => SocialProvider()),

        // ── Trade execution provider (new — trade setup sheet) ──────────────
        ChangeNotifierProvider(create: (_) => TradeExecutionProvider()),

        // ── Feature providers (existing) ────────────────────────────────────
        ChangeNotifierProvider(
          create: (_) {
            final provider = TaskProvider(
              apiService: apiService,
              firebaseService: firebaseService,
              useFirebase: useFirestoreTasks && firebaseReady && !useMockData,
            );
            if (useMockData) MockDataHelper.loadMockData(provider);
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = UserProvider(apiService: apiService);
            if (useMockData) {
              provider.setUser(MockDataHelper.generateMockUser());
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = HeaderProvider(apiService: apiService);
            if (useMockData) {
              provider.setHeader(MockDataHelper.generateMockHeader());
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => AccountConnectionProvider()..loadConnections(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AgentOrchestratorProvider(apiService: apiService),
        ),
      ],

      // ── MaterialApp with light + dark themes ─────────────────────────────
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Tajir',
          debugShowCheckedModeBanner: false,
          // ThemeProvider controls the active mode; default dark per trading
          // app convention. If ThemeProvider exposes a ThemeMode getter, use
          // it; otherwise fall back to getThemeData() for the current mode.
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeProvider.themeMode, // ← honours Settings toggle
          routes: AppRoutes.routes,
          // Preserve existing named-route navigation (AppRoutes.routes).
          // AppShell is reached via _AuthGate; named routes still work for
          // deep links and in-app navigation via Navigator.pushNamed.
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth gate
// ─────────────────────────────────────────────────────────────────────────────

/// Decides whether to show LoginScreen or AppShell.
///
/// Navigation strategy:
/// ─ Firebase enabled (production): StreamBuilder watches authStateChanges().
///   When FirebaseService.signInWithEmail() succeeds it updates the auth state
///   → stream fires → this widget rebuilds to AppShell automatically.
///   onLoginSuccess is a safety-net push in case the stream hasn't propagated.
///
/// ─ Firebase disabled (dev / demo): onLoginSuccess navigates directly.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  void _goToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void _onLoginSuccess(BuildContext context) {
    final modeProvider = context.read<ModeProvider>();
    final target = modeProvider.hasChosen
        ? const AppShell()
        : const OnboardingScreen();
    _goToScreen(context, target);
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = context.watch<ModeProvider>();

    if (!modeProvider.loaded) {
      return const _SplashScreen();
    }

    if (!useFirebaseAuth) {
      return modeProvider.hasChosen
          ? const AppShell()
          : const OnboardingScreen();
    }

    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = snapshot.data;

        if (user != null) {
          return modeProvider.hasChosen
              ? const AppShell()
              : const OnboardingScreen();
        }

        // Not signed in — show login screen with the success callback wired.
        return LoginScreen(
          onLoginSuccess: () => _onLoginSuccess(context),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash screen  (shown while Firebase resolves auth state)
// ─────────────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Replace with your SVG/PNG logo asset when ready.
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.currency_exchange,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              'Tajir',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                fontFamily: 'Inter',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI Forex Financial OS',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.5),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme builder  (from redesign — replaces old ThemeProvider.getThemeData())
// ─────────────────────────────────────────────────────────────────────────────

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final interactiveMouseCursor =
      WidgetStateProperty.resolveWith<MouseCursor?>((states) {
    if (states.contains(WidgetState.disabled)) {
      return SystemMouseCursors.basic;
    }
    return SystemMouseCursors.click;
  });

  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2563EB), // Tajir blue
    brightness: brightness,
    surface: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
    surfaceContainerHighest:
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
    primary: const Color(0xFF3B82F6),
    primaryContainer: const Color(0xFF1D4ED8),
    onPrimary: Colors.white,
    secondary: const Color(0xFF10B981), // Green — profit / buy signals
    onSecondary: Colors.white,
    error: const Color(0xFFEF4444), // Red — loss / sell signals
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Inter', // Add Inter to pubspec.yaml fonts section
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        fontFamily: 'Inter',
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ).copyWith(
        mouseCursor: interactiveMouseCursor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ).copyWith(
        mouseCursor: interactiveMouseCursor,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ).copyWith(
        mouseCursor: interactiveMouseCursor,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ).copyWith(
        mouseCursor: interactiveMouseCursor,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: interactiveMouseCursor,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outline.withValues(alpha: 0.12),
      space: 1,
      thickness: 1,
    ),
    switchTheme: SwitchThemeData(
      mouseCursor: interactiveMouseCursor,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      mouseCursor: interactiveMouseCursor,
    ),
    radioTheme: RadioThemeData(
      mouseCursor: interactiveMouseCursor,
    ),
    listTileTheme: ListTileThemeData(
      mouseCursor: interactiveMouseCursor,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      trackHeight: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontFamily: 'Inter',
        color: colorScheme.onSurface,
      ),
      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
      indicatorColor: colorScheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w700, fontFamily: 'Inter', fontSize: 14),
      unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500, fontFamily: 'Inter', fontSize: 14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.35),
        fontFamily: 'Inter',
        fontSize: 14,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

