import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum SignalAction { buy, sell, hold }

class SignalActionBadge extends StatelessWidget {
  final SignalAction action;

  const SignalActionBadge({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final color = switch (action) {
      SignalAction.buy  => AppTheme.success,
      SignalAction.sell => AppTheme.danger,
      SignalAction.hold => AppTheme.gold,
    };
    final label = action.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: color,
              fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}