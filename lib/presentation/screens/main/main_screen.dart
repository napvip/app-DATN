import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_routes.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == AppRoutes.main) return 0;
    if (location.contains('alerts')) return 1;
    if (location.contains('insights')) return 2;
    if (location.contains('maintenance')) return 3;
    if (location.contains('profile')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.main);
        break;
      case 1:
        context.go(AppRoutes.alerts);
        break;
      case 2:
        context.go(AppRoutes.insights);
        break;
      case 3:
        context.go(AppRoutes.maintenance);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  Future<void> _onPopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;
    SystemSound.play(SystemSoundType.alert);
    if (!mounted) return;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Thoát ứng dụng'),
        content: const Text('Bạn có chắc muốn thoát không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: LucideIcons.home,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    onTap: () => _onItemTapped(context, 0),
                  ),
                  _NavItem(
                    icon: LucideIcons.bell,
                    label: 'Alerts',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onItemTapped(context, 1),
                  ),
                  _NavItem(
                    icon: LucideIcons.trendingUp,
                    label: 'Insights',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onItemTapped(context, 2),
                  ),
                  _NavItem(
                    icon: LucideIcons.wrench,
                    label: 'Maintenance',
                    isSelected: selectedIndex == 3,
                    onTap: () => _onItemTapped(context, 3),
                  ),
                  _NavItem(
                    icon: LucideIcons.user,
                    label: 'Profile',
                    isSelected: selectedIndex == 4,
                    onTap: () => _onItemTapped(context, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(height: 8),
          Icon(
            icon,
            size: 24,
            color: isSelected ? AppColors.primary : AppColors.mutedForeground,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primary : AppColors.mutedForeground,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
