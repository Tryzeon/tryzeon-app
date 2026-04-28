import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';

class IdentitySegmentedControl extends StatelessWidget {
  const IdentitySegmentedControl({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final UserType selectedType;
  final ValueChanged<UserType> onChanged;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPill(
            context: context,
            colorScheme: colorScheme,
            title: '個人專屬',
            isSelected: selectedType == UserType.personal,
            onTap: () => onChanged(UserType.personal),
          ),
          _buildPill(
            context: context,
            colorScheme: colorScheme,
            title: '品牌店家',
            isSelected: selectedType == UserType.store,
            onTap: () => onChanged(UserType.store),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required final BuildContext context,
    required final ColorScheme colorScheme,
    required final String title,
    required final bool isSelected,
    required final VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
          borderRadius: AppRadius.pillAll,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
