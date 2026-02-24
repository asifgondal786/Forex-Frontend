import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/task_provider.dart';
import '../../../services/live_updates_service.dart';

class LiveUpdatesPanel extends StatefulWidget {
  final String taskId;

  const LiveUpdatesPanel({
    super.key,
    required this.taskId,
  });

  @override
  State<LiveUpdatesPanel> createState() => _LiveUpdatesPanelState();
}

class _LiveUpdatesPanelState extends State<LiveUpdatesPanel> {
  StreamSubscription<LiveUpdate>? _ratesSub;
  StreamSubscription<NotificationUpdate>? _notificationsSub;
  StreamSubscription<bool>? _connectionSub;

  final List<String> _events = <String>[];
  LiveUpdate? _latestRate;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final updatesService = context.read<LiveUpdatesService>();
      unawaited(updatesService.connect());

      _connectionSub = updatesService.connectionStatus.listen((connected) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isConnected = connected;
        });
      });

      _ratesSub = updatesService.updates.listen((update) {
        if (!mounted) {
          return;
        }
        setState(() {
          _latestRate = update;
          _events.insert(
            0,
            '${update.pair}: ${update.price.toStringAsFixed(5)} (${update.trend})',
          );
          if (_events.length > 12) {
            _events.removeLast();
          }
        });
      });

      _notificationsSub = updatesService.notifications.listen((notification) {
        if (!mounted) {
          return;
        }
        setState(() {
          _events.insert(0, notification.title);
          if (_events.length > 12) {
            _events.removeLast();
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _ratesSub?.cancel();
    _notificationsSub?.cancel();
    _connectionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = context.watch<TaskProvider>().getTaskById(widget.taskId);

    if (task == null) {
      return _panelScaffold(
        child: const Text(
          'Task not available',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return _panelScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stream, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Live Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ConnectionBadge(isConnected: _isConnected),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: task.progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Step ${task.currentStep} of ${task.totalSteps}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          if (_latestRate != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    _latestRate!.pair,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _latestRate!.price.toStringAsFixed(5),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Recent events',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (_events.isEmpty)
            const Text(
              'Waiting for updates...',
              style: TextStyle(color: Colors.black54),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _events.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      _events[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _panelScaffold({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final bool isConnected;

  const _ConnectionBadge({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppColors.primaryGreen : AppColors.errorRed;
    final label = isConnected ? 'Connected' : 'Disconnected';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
