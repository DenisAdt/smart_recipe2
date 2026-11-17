import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_colors.dart';

/// Navigation item model
class _NavItem {
  final IconData icon;
  final IconData iconFilled;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.iconFilled,
    required this.label,
    required this.route,
  });
}

/// Floating pill-shaped bottom navigation bar — Stitch design.
/// Simple icon+label, active tab shows primary color.
class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;

  const FloatingBottomNav({super.key, required this.currentIndex});

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      iconFilled: Icons.home_rounded,
      label: 'Home',
      route: '/home',
    ),
    _NavItem(
      icon: Icons.search_outlined,
      iconFilled: Icons.search_rounded,
      label: 'Search',
      route: '/search',
    ),
    _NavItem(
      icon: Icons.analytics_outlined,
      iconFilled: Icons.analytics_rounded,
      label: 'Evaluation',
      route: '/evaluation',
    ),
    _NavItem(
      icon: Icons.person_outlined,
      iconFilled: Icons.person_rounded,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  /// Maps a route path prefix to a nav index.
  static int indexFromRoute(String location) {
    if (location.startsWith('/search'))     return 1;
    if (location.startsWith('/evaluation')) return 2;
    if (location.startsWith('/profile'))    return 3;
    return 0; // home (including my-recipes which is under shell)
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.surfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: borderColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            return _NavButton(
              item: _items[index],
              isActive: index == currentIndex,
              isDark: isDark,
              onTap: () {
                if (index != currentIndex) {
                  context.go(_items[index].route);
                }
              },
            );
          }),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.primaryFixed : AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.darkTextTertiary
        : AppColors.textSecondary.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isActive ? item.iconFilled : item.icon,
                key: ValueKey('${item.route}_$isActive'),
                size: 24,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: isActive ? 0 : 0,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
