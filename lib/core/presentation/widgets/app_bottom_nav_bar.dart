import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    super.key,
  });

  static const Key capsuleKey = ValueKey('app_bottom_nav_bar_capsule');
  static const Key selectedPillKey = ValueKey('app_bottom_nav_bar_selected_pill');

  final List<AppBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.bottomNavBarHorizontalMargin,
        0,
        AppSpacing.bottomNavBarHorizontalMargin,
        safeAreaBottom + AppSpacing.bottomNavBarBottomMargin,
      ),
      child: Center(
        heightFactor: 1,
        child: Container(
          key: capsuleKey,
          height: AppSpacing.bottomNavBarHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: colorScheme.outline, width: AppStroke.thin),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: AppOpacity.medium),
                blurRadius: AppSpacing.md,
                offset: const Offset(0, AppSpacing.xs),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, item) in items.indexed)
                    Flexible(
                      child: SizedBox(
                        width: AppSpacing.bottomNavBarItemWidth,
                        child: _NavItem(
                          item: item,
                          selected: index == selectedIndex,
                          onTap: () => onTap(index),
                        ),
                      ),
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
  const _NavItem({required this.item, required this.selected, required this.onTap});

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selected ? item.selectedIcon : item.icon,
          size: AppSpacing.lg,
          color: foreground,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          item.label,
          style: textTheme.labelMedium?.copyWith(
            color: foreground,
            letterSpacing: 0,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: DecoratedBox(
            key: selected ? AppBottomNavBar.selectedPillKey : null,
            decoration: BoxDecoration(
              color: selected ? colorScheme.surfaceContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.smMd,
                vertical: AppSpacing.xs,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
