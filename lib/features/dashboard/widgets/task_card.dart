import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/task_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusChip(status: task.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoChip(
                icon: Icons.flag_outlined,
                label: 'Priority: ${task.priority.name.toUpperCase()}',
                color: _priorityColor(task.priority),
              ),
              const SizedBox(width: 14),
              _InfoChip(
                icon: Icons.list_alt_outlined,
                label: 'Steps: ${task.currentStep}/${task.totalSteps}',
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (task.status == TaskStatus.running)
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<TaskProvider>().pauseTask(task.id);
                  },
                  icon: const Icon(Icons.pause, size: 16),
                  label: const Text('Pause'),
                ),
              if (task.status == TaskStatus.paused)
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<TaskProvider>().resumeTask(task.id);
                  },
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Resume'),
                ),
              if (task.status == TaskStatus.running || task.status == TaskStatus.paused)
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<TaskProvider>().stopTask(task.id);
                  },
                  icon: const Icon(Icons.stop, size: 16),
                  label: const Text('Stop'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final TaskStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.running:
        return AppColors.statusRunning;
      case TaskStatus.completed:
        return AppColors.statusCompleted;
      case TaskStatus.pending:
        return AppColors.statusPending;
      case TaskStatus.failed:
        return AppColors.errorRed;
      case TaskStatus.paused:
        return AppColors.pauseButton;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
