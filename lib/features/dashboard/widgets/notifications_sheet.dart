// lib/features/dashboard/widgets/notifications_sheet.dart
// Bottom sheet showing push notification history.
// Uses FirebaseService (not deleted LiveUpdatesService / HeaderProvider).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/app_notification.dart';
import '../../../services/firebase_service.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  /// Convenience method â€” call from any screen to show the sheet.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fs = context.read<FirebaseService>();
      final list = await fs.getNotificationHistory();
      setState(() {
        _notifications = list;
        _loading = false;
      });
    } catch (_) {
      // Fallback â€” show empty gracefully
      setState(() => _loading = false);
    }
  }

  Future<void> _clearAll() async {
    final fs = context.read<FirebaseService>();
    await fs.clearNotificationHistory();
    setState(() => _notifications = []);
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _handle(),
            _header(),
            const Divider(color: AppColors.bg3, height: 1),
            Expanded(child: _body(controller)),
          ],
        ),
      ),
    );
  }

  Widget _handle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          const Text('Notifications',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear all',
                  style: TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _body(ScrollController controller) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_notifications.isEmpty) {
      return _EmptyState();
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.bg3, height: 1, indent: 72),
      itemBuilder: (_, i) => _NotificationTile(n: _notifications[i]),
    );
  }
}

// â”€â”€ Notification tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> n;
  const _NotificationTile({required this.n});

  Color get _iconColor => switch (n['category']) {
    'signal' => AppColors.gold,
    'trade'  => AppColors.success,
    'alert'  => AppColors.danger,
    _        => AppColors.primary,
  };

  IconData get _icon => switch (n['category']) {
    'signal' => Icons.trending_up_rounded,
    'trade'  => Icons.check_circle_outline_rounded,
    'alert'  => Icons.warning_amber_rounded,
    _        => Icons.notifications_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _iconColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(_icon, color: _iconColor, size: 20),
      ),
      title: Text(n['title'] as String? ?? '',
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((n['message'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text((n['message'] as String? ?? ''),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 4),
          Text(_timeAgo((n['timestamp'] != null ? DateTime.tryParse(n['timestamp'].toString()) : null)),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
      isThreeLine: (n['message'] as String? ?? '').isNotEmpty,
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('No notifications yet',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Signal alerts and trade updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}



