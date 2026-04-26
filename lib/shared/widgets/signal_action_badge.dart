import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SignalActionBadge extends StatelessWidget {
  final String action;
  final bool large;
  const SignalActionBadge({super.key, required this.action, this.large = false});

  @override
  Widget build(BuildContext context) {
    final a = action.toLowerCase();
    final color = a == 'buy' ? AppTheme.primary : a == 'sell' ? AppTheme.danger : AppTheme.gold;
    final icon  = a == 'buy' ? Icons.trending_up_rounded : a == 'sell' ? Icons.trending_down_rounded : Icons.pause_rounded;
    final size  = large ? 14.0 : 11.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: size + 4),
          const SizedBox(width: 4),
          Text(action.toUpperCase(), style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}
