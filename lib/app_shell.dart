import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/dashboard/home_screen.dart';
import 'features/market_watch/market_watch_screen.dart';
import 'features/trade_signals/trade_signals_screen.dart';
import 'features/portfolio/portfolio_screen.dart';
import 'features/more/more_screen.dart';
import 'shared/widgets/bottom_nav_bar.dart';
import 'shared/widgets/connection_banner.dart';
import 'providers/app_shell_provider.dart';
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  static const _screens = [
    HomeScreen(),
    MarketWatchScreen(),
    TradeSignalsScreen(),
    PortfolioScreen(),
    MoreScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectionBanner(),
          Expanded(
            child: Consumer<AppShellProvider>(
              builder: (context, shellProvider, _) {
                return IndexedStack(
                  index: shellProvider.currentIndex,
                  children: _screens,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<AppShellProvider>(
        builder: (context, shellProvider, _) {
          return TajirBottomNavBar(
            currentIndex: shellProvider.currentIndex,
            onTap: (index) => shellProvider.setTab(index),
          );
        },
      ),
    );
  }
}
