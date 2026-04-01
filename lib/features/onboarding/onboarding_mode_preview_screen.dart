import 'package:flutter/material.dart';

import '../../app_shell.dart';
import '../../providers/mode_provider.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../custom_setup/custom_setup_screen.dart';
import '../embodied_agent/embodied_agent_screen.dart';
import '../market_watch/market_watch_screen.dart';
import '../news/news_events_screen.dart';
import '../paper_trading/paper_trading_screen.dart';
import '../trade_signals/trade_signals_screen.dart';

class OnboardingModePreviewScreen extends StatelessWidget {
  final AppMode mode;

  const OnboardingModePreviewScreen({
    super.key,
    required this.mode,
  });

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  Widget _buildScreen() {
    return switch (mode) {
      AppMode.marketWatch => const MarketWatchScreen(),
      AppMode.aiChat => const AiChatScreen(),
      AppMode.aiCopilot => const EmbodiedAgentScreen(),
      AppMode.tradeSignals => const TradeSignalsScreen(),
      AppMode.newsEvents => const NewsEventsScreen(),
      AppMode.customSetup => const CustomSetupScreen(),
      AppMode.paperTrading => const PaperTradingScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildScreen()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _OverlayPillButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'On Boarding Screen',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _OverlayPillButton(
                    icon: Icons.home_rounded,
                    label: 'Home Dashboard',
                    onTap: () => _goHome(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OverlayPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
