import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'signals/signal_screen.dart';
import 'charts/chart_screen.dart';
import 'agent/agent_screen.dart';
import 'settings/settings_screen.dart';
import '../shared/widgets/bottom_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SignalScreen(),
    const ChartScreen(),
    const AgentScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
