import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/responsive.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    bool isActive(String path) {
      if (path == '/missions' && location.startsWith('/missions')) return true;
      return location == path;
    }

    return Container(
      width: context.screenWidth * 0.9,
      constraints: const BoxConstraints(maxWidth: 300),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            icon: Icons.home_filled,
            isActive: isActive('/home') || location == '/',
            onTap: () => context.go('/home'),
          ),
          _NavItem(
            icon: Icons.flag,
            isActive: isActive('/missions'),
            onTap: () => context.go('/missions'),
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            isActive: isActive('/progress'),
            onTap: () => context.go('/progress'),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            isActive: isActive('/profile'),
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
          size: 24,
        ),
      ),
    );
  }
}
