import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/market_provider.dart';
import '../../providers/signal_provider.dart';
import '../../shared/widgets/signal_action_badge.dart';
import '../../shared/widgets/shimmer_box.dart';

class SignalsScreen extends StatelessWidget {
  const SignalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Column(
          children: [
            _SignalsHeader(),
            _PairSelector(),
            Expanded(child: _SignalBody()),
          ],
        ),
      ),
    );
  }
}

class _SignalsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sig = context.watch<SignalProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text('AI Signals',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const Spacer(),
          if (sig.lastGenerated != null)
            Text(
              'Updated ${DateFormat.Hm().format(sig.lastGenerated!)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              final pair = context.read<MarketProvider>().selectedPair;
              context.read<SignalProvider>().generateSignals(pair: pair);
            },
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _PairSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: market.pairs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final pair = market.pairs[i];
            final selected = pair == market.selectedPair;
            return GestureDetector(
              onTap: () {
                market.selectPair(pair);
                context.read<SignalProvider>().generateSignals(pair: pair);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.bg2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(pair,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? AppColors.bg0 : AppColors.textSecondary,
                      )),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SignalBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    final signals = context.watch<SignalProvider>();
    final signal = signals.signalFor(market.selectedPair);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.bg1,
      onRefresh: () => signals.generateSignals(pair: market.selectedPair),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Main signal card
          signals.isGenerating || signal == null
              ? const ShimmerBox(width: double.infinity, height: 220, radius: 16)
              : _MainSignalCard(signal: signal),
          const SizedBox(height: 16),

          // Indicators stub
          _IndicatorsCard(pair: market.selectedPair),
          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withAlpha(50)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI signals are for informational purposes only and do not constitute financial advice. Trading forex involves significant risk of loss.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainSignalCard extends StatefulWidget {
  final SignalData signal;
  const _MainSignalCard({required this.signal});

  @override
  State<_MainSignalCard> createState() => _MainSignalCardState();
}

class _MainSignalCardState extends State<_MainSignalCard> {
  int _level = 1; // 0=simple, 1=standard, 2=advanced

  String get _reasoning {
    final full = widget.signal.reasoning;
    if (_level == 0) {
      final sentences = full.split('. ');
      return sentences.isNotEmpty ? '${sentences.first}.' : full;
    }
    if (_level == 1) return full.length > 200 ? '${full.substring(0, 200)}...' : full;
    return full;
  }

  @override
  Widget build(BuildContext context) {
    final signal = widget.signal;
    final color = signal.action == SignalAction.buy
        ? AppColors.success
        : signal.action == SignalAction.sell
            ? AppColors.danger
            : AppColors.gold;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glowCard(color: color, intensity: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SignalActionBadge(action: signal.action, large: true),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(signal.pair,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(
                    'Confidence: ${(signal.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: signal.confidence,
            backgroundColor: AppColors.bg3,
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 5,
          ),
          const SizedBox(height: 16),

          // Levels
          Row(
            children: [
              _LevelChip('Simple', 0, _level, () => setState(() => _level = 0)),
              const SizedBox(width: 6),
              _LevelChip('Standard', 1, _level, () => setState(() => _level = 1)),
              const SizedBox(width: 6),
              _LevelChip('Advanced', 2, _level, () => setState(() => _level = 2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_reasoning,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.6)),

          if (signal.entry != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _EntryField('Entry', signal.entry, AppColors.textPrimary),
                _EntryField('Stop Loss', signal.stopLoss, AppColors.danger),
                _EntryField('Take Profit', signal.takeProfit, AppColors.success),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final int value;
  final int current;
  final VoidCallback onTap;

  const _LevelChip(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withAlpha(30) : AppColors.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: sel ? AppColors.primary : AppColors.textMuted,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

class _EntryField extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _EntryField(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value?.toStringAsFixed(5) ?? 'â€”',
          style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _IndicatorsCard extends StatelessWidget {
  final String pair;
  const _IndicatorsCard({required this.pair});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Indicators',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          _IndicatorRow('RSI (14)', 'â€”', 'Neutral', AppColors.gold),
          const SizedBox(height: 10),
          _IndicatorRow('MACD', 'â€”', 'Neutral', AppColors.gold),
          const SizedBox(height: 10),
          _IndicatorRow('EMA 20/50', 'â€”', 'Neutral', AppColors.gold),
          const SizedBox(height: 10),
          Center(
            child: Text('Indicators load when backend returns data.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final String name;
  final String value;
  final String signal;
  final Color signalColor;

  const _IndicatorRow(this.name, this.value, this.signal, this.signalColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: signalColor.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(signal,
              style: TextStyle(fontSize: 11, color: signalColor, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
