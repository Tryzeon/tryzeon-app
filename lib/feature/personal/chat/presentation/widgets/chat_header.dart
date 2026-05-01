import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '穿搭顧問',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'STYLE ADVISOR',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  size: AppSpacing.lg,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: onRefresh,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
