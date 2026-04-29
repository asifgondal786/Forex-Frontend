import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';

class SignalCard extends StatelessWidget {
  final SignalData signal;
  final bool showDisclaimer;
  final bool compact;

  const SignalCard({
    super.key,
    required this.signal,
    this.showDisclaimer = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _actionBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (!compact) ...[
            Divider(height: 1, color: AppTheme.bg2),
            _buildDetails(),
          ],
          if (!compact && signal.reasoning != null) ...[
            Divider(height: 1, color: AppTheme.bg2),
            _buildReasoning(),
          ],
          if (showDisclaimer) ...[
            Divider(height: 1, color: AppTheme.bg2),
            _buildDisclaimer(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Action badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _actionColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _actionColor().withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_actionIcon(), color: _actionColor(), size: 16),
                const SizedBox(width: 6),
                Text(
                  signal.action.toUpperCase(),
                  style: TextStyle(
                    color: _actionColor(),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.pair,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Confidence: ${(signal.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Confidence ring
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: signal.confidence,
                  backgroundColor: AppTheme.bg3,
                  valueColor: AlwaysStoppedAnimation<Color>(_actionColor()),
                  strokeWidth: 3,
                ),
                Center(
                  child: Text(
                    '${(signal.confidence * 100).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: _actionColor(),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (signal.entryPrice != null)
            _DetailChip(
              label: 'Entry',
              value: signal.entryPrice!.toStringAsFixed(5),
              color: AppTheme.textPrimary,
            ),
          if (signal.stopLoss != null) ...[
            const SizedBox(width: 8),
            _DetailChip(
              label: 'SL',
              value: signal.stopLoss!.toStringAsFixed(5),
              color: AppTheme.danger,
            ),
          ],
          if (signal.takeProfit != null) ...[
            const SizedBox(width: 8),
            _DetailChip(
              label: 'TP',
              value: signal.takeProfit!.toStringAsFixed(5),
              color: AppTheme.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasoning() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI ANALYSIS',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            signal.reasoning!,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.textSecondary, size: 12),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'AI signals are not financial advice. Trade at your own risk.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor() {
    switch (signal.action.toLowerCase()) {
      case 'buy':
        return AppTheme.primary;
      case 'sell':
        return AppTheme.danger;
      default:
        return AppTheme.gold;
    }
  }

  Color _actionBorderColor() {
    return _actionColor().withValues(alpha: 0.25);
  }

  IconData _actionIcon() {
    switch (signal.action.toLowerCase()) {
      case 'buy':
        return Icons.trending_up_rounded;
      case 'sell':
        return Icons.trending_down_rounded;
      default:
        return Icons.pause_rounded;
    }
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

