// lib/features/news/event_countdown_widget.dart
// Shows upcoming forex economic calendar events with a live countdown timer.
// Fetches from backend /api/v1/news — no deleted providers used.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

// ── Impact level colours ──────────────────────────────────────────────────────
const Color _kAmber  = Color(0xFFFFB800);
const Color _kGreen  = Color(0xFF2ED573);
const Color _kBlue   = Color(0xFF3A86FF);

enum NewsImpact { high, medium, low }

class NewsEvent {
  final String title;
  final String currency;
  final DateTime time;
  final NewsImpact impact;
  final String? forecast;
  final String? previous;

  const NewsEvent({
    required this.title,
    required this.currency,
    required this.time,
    required this.impact,
    this.forecast,
    this.previous,
  });

  factory NewsEvent.fromJson(Map<String, dynamic> j) {
    final impactStr = (j['impact'] as String? ?? 'low').toLowerCase();
    return NewsEvent(
      title:    j['title']    as String? ?? 'Unknown Event',
      currency: j['currency'] as String? ?? 'USD',
      time:     DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
      impact:   impactStr == 'high'
                  ? NewsImpact.high
                  : impactStr == 'medium'
                      ? NewsImpact.medium
                      : NewsImpact.low,
      forecast: j['forecast'] as String?,
      previous: j['previous'] as String?,
    );
  }
}

// ── Public widget ─────────────────────────────────────────────────────────────
class EventCountdownWidget extends StatefulWidget {
  const EventCountdownWidget({super.key});

  @override
  State<EventCountdownWidget> createState() => _EventCountdownWidgetState();
}

class _EventCountdownWidgetState extends State<EventCountdownWidget> {
  List<NewsEvent> _events = [];
  bool _loading = true;
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh countdown every second
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiService>();
      final data = await api.fetchNews();
      final raw  = data['events'] as List<dynamic>? ?? [];
      setState(() {
        _events  = raw
            .map((e) => NewsEvent.fromJson(e as Map<String, dynamic>))
            .where((e) => e.time.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _ShimmerList();
    if (_error != null) {
      return _ErrorTile(message: _error!, onRetry: _load);
    }
    if (_events.isEmpty) {
      return const _EmptyTile();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(onRefresh: _load),
        ..._events.take(5).map((e) => _EventTile(event: e)),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  const _SectionHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          const Text('Upcoming Events',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Single event tile ─────────────────────────────────────────────────────────
class _EventTile extends StatelessWidget {
  final NewsEvent event;
  const _EventTile({required this.event});

  Color get _impactColor => switch (event.impact) {
    NewsImpact.high   => AppColors.danger,
    NewsImpact.medium => _kAmber,
    NewsImpact.low    => _kGreen,
  };

  String get _impactLabel => switch (event.impact) {
    NewsImpact.high   => 'HIGH',
    NewsImpact.medium => 'MED',
    NewsImpact.low    => 'LOW',
  };

  String _countdown() {
    final diff = event.time.difference(DateTime.now());
    if (diff.isNegative) return 'Live';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.bg3),
      ),
      child: Row(
        children: [
          // Impact badge
          Container(
            width: 38,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _impactColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(_impactLabel,
                style: TextStyle(
                    color: _impactColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          // Currency chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(event.currency,
                style: const TextStyle(
                    color: _kBlue, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Text(event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          // Countdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_countdown(),
                  style: TextStyle(
                      color: event.impact == NewsImpact.high
                          ? AppColors.danger
                          : AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              if (event.forecast != null)
                Text('F: ${event.forecast}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Loading shimmer list ───────────────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ── Error tile ────────────────────────────────────────────────────────────────
class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Could not load events',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyTile extends StatelessWidget {
  const _EmptyTile();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text('No upcoming events',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}