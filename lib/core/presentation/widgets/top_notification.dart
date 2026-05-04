import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Failure-only top banner (Direction A — refined card).
/// White surface, soft tinted icon container, generous radius, lifted shadow.
/// Success states stay silent; download-style results use AppSnackBar.
class TopNotification {
  static void show(final BuildContext context, {required final String message}) {
    HapticFeedback.mediumImpact();

    toastification.showCustom(
      context: context,
      autoCloseDuration: AppDuration.toast,
      alignment: Alignment.topCenter,
      direction: TextDirection.ltr,
      animationDuration: AppDuration.slow,
      animationBuilder: (final context, final animation, final alignment, final child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: AppCurves.emphasized)),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: AppCurves.emphasized),
            child: child,
          ),
        );
      },
      builder: (final context, final holder) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadius.dialogAll,
                border: Border.all(color: colorScheme.outline),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: AppOpacity.light),
                    blurRadius: 40,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.dialogAll,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => toastification.dismiss(holder),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.smMd,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.smMd),
                          Expanded(
                            child: Text(
                              message,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
