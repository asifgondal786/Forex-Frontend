import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/task_provider.dart';

class TaskHistoryTable extends StatelessWidget {
  const TaskHistoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = List<Task>.from(taskProvider.tasks)
          ..sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

        final rows = tasks.take(6).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No task history yet.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 42,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 54,
                    columns: const [
                      DataColumn(label: Text('Task')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Priority')),
                      DataColumn(label: Text('Progress')),
                      DataColumn(label: Text('Created')),
                    ],
                    rows: rows
                        .map(
                          (task) => DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    task.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(_StatusBadge(status: task.status)),
                              DataCell(Text(task.priority.name.toUpperCase())),
                              DataCell(
                                Text('${task.currentStep}/${task.totalSteps}'),
                              ),
                              DataCell(Text(_formatDate(task.createdAt))),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$month/$day/$year';
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _colorFor(TaskStatus status) {
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
