import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../core/theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'signals/signal_screen.dart';
import 'charts/chart_screen.dart';
import 'agent/agent_screen.dart';
import 'settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(),
    SignalsScreen(),
    ChartScreen(),
    AgentScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<AgentProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppTheme.bg1,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.signal_cellular_alt_rounded), label: 'Signals'),
          const BottomNavigationBarItem(icon: Icon(Icons.candlestick_chart_rounded), label: 'Charts'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.smart_toy_rounded),
                if (agent.mode != AgentMode.off)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: agent.mode == AgentMode.fullAuto ? AppTheme.primary : AppTheme.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Agent',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}


