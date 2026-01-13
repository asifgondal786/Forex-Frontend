import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key});

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Forex Market Summary for Today',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.statusRunning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.play_arrow, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Running',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Task Details
          Row(
            children: [
              const Text(
                'Start: Apr 24, 2024, 12:00 PM',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(width: 24),
              Row(
                children: const [
                  Text(
                    'Priority: ',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  Icon(Icons.circle, size: 12, color: AppColors.priorityMedium),
                  SizedBox(width: 4),
                  Text(
                    'Medium',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progress Bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Progress: 3 / 4',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Icon(Icons.refresh, size: 18, color: Colors.black54),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.75,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Steps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StepItem(
                icon: Icons.check_circle,
                label: 'Research Data',
                isCompleted: true,
              ),
              _StepItem(
                icon: Icons.check_circle,
                label: 'Analyze Trends',
                isCompleted: true,
                hasInfo: true,
              ),
              _StepItem(
                icon: Icons.check_circle,
                label: 'Generate Summary',
                isCompleted: true,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // AI Generated Result
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Generated Result:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'forex_market_summary_today.pdf (52 KB)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Download'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('View'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Suggest Next Task
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text('Suggest Next Task'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCompleted;
  final bool hasInfo;

  const _StepItem({
    required this.icon,
    required this.label,
    this.isCompleted = false,
    this.hasInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isCompleted ? AppColors.primaryGreen : Colors.grey,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isCompleted ? Colors.black87 : Colors.black54,
            fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        if (hasInfo) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.blue.shade300,
          ),
        ],
      ],
    );
  }
}