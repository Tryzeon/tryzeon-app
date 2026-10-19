import 'package:flutter/material.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatFailureCard extends StatelessWidget {
  const ChatFailureCard({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final action = switch (failure) {
      RateLimitFailure() || ValidationFailure() => null,
      _ => TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: AppSpacing.md),
        label: const Text('重試'),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: AppSpacing.mdLg,
              color: colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                failure.displayMessage(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        ?action,
      ],
    );
  }
}
