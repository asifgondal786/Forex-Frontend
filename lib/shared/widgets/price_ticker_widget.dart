import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/market_provider.dart';

class PriceTickerWidget extends StatelessWidget {
  const PriceTickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();

    return Container(
      height: 64,
      child: market.isLoading && market.prices.isEmpty
          ? _buildShimmer()
          : market.prices.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: market.prices.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final p = market.prices[i];
                    return _PriceTile(price: p);
                  },
                ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, __) => Container(
        width: 110,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'No price data',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final PriceData price;

  const _PriceTile({required this.price});

  @override
  Widget build(BuildContext context) {
    final isUp = price.change >= 0;
    final changeColor = isUp ? AppTheme.success : AppTheme.danger;
    final changeIcon = isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down;

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bg2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            price.pair,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            price.bid.toStringAsFixed(price.pair.contains('JPY') ? 3 : 5),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(changeIcon, color: changeColor, size: 14),
              Text(
                '${isUp ? '+' : ''}${price.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: changeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
