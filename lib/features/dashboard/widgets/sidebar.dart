import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    const items = <_SidebarItem>[
      _SidebarItem(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        route: AppRoutes.dashboard,
      ),
      _SidebarItem(
        icon: Icons.add_task_outlined,
        label: 'New Task',
        route: AppRoutes.createTask,
      ),
      _SidebarItem(
        icon: Icons.history_outlined,
        label: 'History',
        route: AppRoutes.taskHistory,
      ),
      _SidebarItem(
        icon: Icons.smart_toy_outlined,
        label: 'AI Chat',
        route: AppRoutes.aiChat,
      ),
      _SidebarItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        route: AppRoutes.settings,
      ),
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.sidebarDark,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Forex Companion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SidebarTile(
                    item: item,
                    selected: currentRoute == item.route,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _SidebarItem item;
  final bool selected;

  const _SidebarTile({
    required this.item,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.primaryBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute == item.route) {
            return;
          }
          Navigator.pushNamed(context, item.route);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? selectedColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: selected ? selectedColor : Colors.white70,
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  color: selected ? selectedColor : Colors.white70,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  final String route;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
