import 'package:flutter/material.dart';
import 'providers/mode_provider.dart';
import 'services/firebase_service.dart';
import 'core/models/app_models.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/agent_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/broker_provider.dart';
import 'providers/market_provider.dart';
import 'providers/signal_provider.dart';
import 'providers/mode_provider.dart';
import 'services/api_service.dart';
import 'features/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TajirApp());
}

class TajirApp extends StatelessWidget {
  const TajirApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => api),
        ChangeNotifierProvider(create: (_) => ModeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(FirebaseService())),
        ChangeNotifierProvider(create: (_) => AgentProvider(api)),
        ChangeNotifierProvider(create: (_) => BrokerProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider(api)),
        ChangeNotifierProvider(create: (_) => SignalProvider(api)),
      ],
      child: MaterialApp(
        title: 'Tajir',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}






