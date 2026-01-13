import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TaskHistoryTable extends StatelessWidget {
  const TaskHistoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Table Header
          Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Task',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Priority',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(height: 32),
          
          // Table Rows
          _TaskRow(
            taskName: 'Automate Daily Forex Report',
            status: 'Completed',
            priority: 'Apr 23, 2024, 2:45 PM',
            statusColor: AppColors.statusCompleted,
          ),
          
          const SizedBox(height: 16),
          
          _TaskRow(
            taskName: 'Generate Forex Trade Ideas',
            status: 'Completed',
            priority: 'Apr 22, 2024, 3:12 PM',
            statusColor: AppColors.statusCompleted,
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String taskName;
  final String status;
  final String priority;
  final Color statusColor;

  const _TaskRow({
    required this.taskName,
    required this.status,
    required this.priority,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  taskName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            priority,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}