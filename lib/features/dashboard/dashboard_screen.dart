import 'package:flutter/material.dart';
import 'widgets/sidebar.dart';
import 'widgets/dashboard_content.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          const Sidebar(),
          
          // Main Content Area
          Expanded(
            child: DashboardContent(),
          ),
        ],
      ),
    );
  }
}