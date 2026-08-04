import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Subjects',
    ),
    _NavItem(
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt_rounded,
      label: 'Exams',
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_alt_rounded,
      label: 'Friends',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevatedSurface : Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF26345D))
                  .withValues(alpha: isDark ? 0.34 : 0.14),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (int index = 0; index < _items.length; index++) ...[
                if (index > 0) const SizedBox(width: 3),
                Expanded(
                  child: _NavButton(
                    item: _items[index],
                    selected: currentIndex == index,
                    isDark: isDark,
                    onTap: () => onTap(index),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark
        ? AppColors.textMuted
        : AppColors.textSecondary.withValues(alpha: 0.86);

    return Semantics(
      button: true,
      selected: selected,
      label: '${item.label} tab',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            heightFactor: 1,
            child: SizedBox(
              width: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      width: selected ? 34 : 30,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.premiumGradient : null,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.28),
                                  blurRadius: 9,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          selected ? item.selectedIcon : item.icon,
                          key: ValueKey(selected),
                          size: selected ? 19 : 20,
                          color: selected ? Colors.white : inactiveColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: selected
                                ? (isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primaryDark)
                                : inactiveColor,
                            fontSize: 9.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
