import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/market_provider.dart';
import '../../providers/signal_provider.dart';
import '../../providers/broker_provider.dart';
import '../../providers/agent_provider.dart';
import '../../services/api_service.dart';
import '../../shared/widgets/signal_action_badge.dart';
import '../../shared/widgets/shimmer_box.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _news = [];
  Map<String, dynamic>? _sentiment;
  bool _newsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final api = context.read<ApiService>();
    try {
      final news = await api.fetchNews();
      final sent = await api.fetchMarketSentiment();
      if (!mounted) return;
      setState(() {
        _news = (news['news'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .take(3)
            .toList();
        _sentiment = sent;
        _newsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _newsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.bg1,
          onRefresh: () async {
            context.read<MarketProvider>().fetchPrices();
            context.read<SignalProvider>().generateSignals();
            _loadExtras();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Header(),
              const SizedBox(height: 20),
              _PriceTicker(),
              const SizedBox(height: 16),
              _SignalCard(),
              const SizedBox(height: 16),
              _SentimentCard(sentiment: _sentiment),
              const SizedBox(height: 16),
              _AgentStatusCard(),
              const SizedBox(height: 16),
              _NewsSection(news: _news, isLoading: _newsLoading),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final broker = context.watch<BrokerProvider>();
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(DateFormat('EEE, dd MMM').format(DateTime.now()),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const Spacer(),
        if (broker.isConnected) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(broker.modeLabel,
                    style: const TextStyle(
                        color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
            color: AppColors.bg2, shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_outlined,
              color: AppColors.textSecondary, size: 18),
        ),
      ],
    );
  }
}

// â”€â”€ Price Ticker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PriceTicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Live Prices',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: market.isLoading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, __) =>
                      const ShimmerBox(width: 120, height: 88, radius: 12),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: market.pairs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final pair = market.pairs[i];
                    final price = market.prices[pair];
                    return _PriceChip(pair: pair, data: price);
                  },
                ),
        ),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String pair;
  final PriceData? data;

  const _PriceChip({required this.pair, this.data});

  @override
  Widget build(BuildContext context) {
    final up = data?.isUp ?? true;
    final color = up ? AppColors.success : AppColors.danger;
    return GestureDetector(
      onTap: () {
        context.read<MarketProvider>().selectPair(pair);
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(pair,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: color, size: 18),
              ],
            ),
            Text(
              data?.displayBid ?? 'â€”',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color),
            ),
            Text(
              data != null
                  ? '${up ? '+' : ''}${data!.changePercent.toStringAsFixed(2)}%'
                  : 'â€”',
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Signal Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SignalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    final signals = context.watch<SignalProvider>();
    final signal = signals.signalFor(market.selectedPair);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Latest Signal',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const Spacer(),
              Text(market.selectedPair,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              if (signals.isGenerating) ...[
                const SizedBox(width: 8),
                const SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppColors.primary)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (signal == null)
            const ShimmerBox(width: double.infinity, height: 60, radius: 8)
          else ...[
            Row(
              children: [
                SignalActionBadge(action: signal.action),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confidence: ${(signal.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: signal.confidence,
                        backgroundColor: AppColors.bg3,
                        valueColor: AlwaysStoppedAnimation(_confidenceColor(signal.confidence)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (signal.entry != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _PriceLabel('Entry', signal.entry!, AppColors.textSecondary),
                  const SizedBox(width: 16),
                  _PriceLabel('SL', signal.stopLoss, AppColors.danger),
                  const SizedBox(width: 16),
                  _PriceLabel('TP', signal.takeProfit, AppColors.success),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _confidenceColor(double c) {
    if (c >= 0.7) return AppColors.success;
    if (c >= 0.5) return AppColors.gold;
    return AppColors.danger;
  }
}

class _PriceLabel extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _PriceLabel(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(
          value?.toStringAsFixed(5) ?? 'â€”',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// â”€â”€ Sentiment Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SentimentCard extends StatelessWidget {
  final Map<String, dynamic>? sentiment;
  const _SentimentCard({this.sentiment});

  @override
  Widget build(BuildContext context) {
    final bull = (sentiment?['bullish'] as num?)?.toDouble() ?? 0.5;
    final label = bull >= 0.6 ? 'Bullish' : bull <= 0.4 ? 'Bearish' : 'Neutral';
    final color = bull >= 0.6
        ? AppColors.success
        : bull <= 0.4
            ? AppColors.danger
            : AppColors.gold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Market Sentiment',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withAlpha(120), blurRadius: 6)]),
                  ),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${(bull * 100).toStringAsFixed(0)}% Bullish',
                    style: const TextStyle(fontSize: 11, color: AppColors.success)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: bull,
                    backgroundColor: AppColors.danger.withAlpha(60),
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${((1 - bull) * 100).toStringAsFixed(0)}% Bearish',
                    style: const TextStyle(fontSize: 11, color: AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Agent Status Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AgentStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final agent = context.watch<AgentProvider>();
    if (agent.mode == AgentMode.off) return const SizedBox.shrink();

    final color = agent.mode == AgentMode.fullAuto ? AppColors.accent : AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glowCard(color: color, intensity: 0.25),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withAlpha(180), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agent ${agent.modeLabel}',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              Text(
                agent.mode == AgentMode.semiAuto
                    ? '${agent.pendingTrades.length} trade(s) awaiting approval'
                    : '${agent.activeTrades.length} active trade(s)',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.smart_toy_outlined, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}

// â”€â”€ News Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NewsSection extends StatelessWidget {
  final List<Map<String, dynamic>> news;
  final bool isLoading;

  const _NewsSection({required this.news, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Market News',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        if (isLoading)
          Column(
            children: List.generate(3, (_) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: const ShimmerBox(width: double.infinity, height: 64, radius: 12),
                )),
          )
        else if (news.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: const Center(
              child: Text('No news available',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          )
        else
          ...news.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NewsItem(item: item),
              )),
      ],
    );
  }
}

class _NewsItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _NewsItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final sentiment = item['sentiment'] as String? ?? 'neutral';
    final color = sentiment == 'positive'
        ? AppColors.success
        : sentiment == 'negative'
            ? AppColors.danger
            : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3, height: 40,
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String? ?? 'No title',
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item['source'] as String? ?? '',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



