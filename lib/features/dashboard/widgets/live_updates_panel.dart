import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LiveUpdatesPanel extends StatelessWidget {
  const LiveUpdatesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Updates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.stop_circle, color: Colors.red),
                    tooltip: 'Stop',
                    iconSize: 24,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.menu, color: Colors.black54),
                    tooltip: 'Menu',
                    iconSize: 24,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Updates List
          _UpdateItem(
            text: 'AI generated a market summary report detailing today\'s key Forex trends.',
            isCompleted: true,
          ),
          const SizedBox(height: 16),
          _UpdateItem(
            text: 'AI completed analysis of Forex market data and identified key trends.',
            isCompleted: true,
          ),
          const SizedBox(height: 16),
          _UpdateItem(
            text: 'AI is analyzing Forex market data for today...',
            isCompleted: false,
            isInProgress: true,
            progress: 0.65,
          ),
          
          const SizedBox(height: 24),
          
          // Control Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.stopButton,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Stop',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.pause),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Task History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Task History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/task-history');
                },
                child: const Text('View All'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _HistoryItem(
            status: 'Completed',
            date: 'Apr 23, 2024, 2:45 PM',
          ),
          const SizedBox(height: 12),
          _HistoryItem(
            status: 'Completed',
            date: 'Apr 22, 2024, 3:12 PM',
          ),
        ],
      ),
    );
  }
}

class _UpdateItem extends StatelessWidget {
  final String text;
  final bool isCompleted;
  final bool isInProgress;
  final double? progress;

  const _UpdateItem({
    required this.text,
    this.isCompleted = false,
    this.isInProgress = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: isCompleted ? AppColors.primaryGreen : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              if (isInProgress && progress != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String status;
  final String date;

  const _HistoryItem({
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: AppColors.statusCompleted,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}