import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatProgressBar extends StatelessWidget {
  const ChatProgressBar({
    super.key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    this.isVisible = true,
  });

  final int currentQuestionIndex;
  final int totalQuestions;
  final bool isVisible;

  @override
  Widget build(final BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final progress = totalQuestions > 0 ? currentQuestionIndex / totalQuestions : 0.0;

    return LayoutBuilder(
      builder: (final context, final constraints) {
        return Container(
          height: AppSpacing.xxs,
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: AppDuration.standard,
            curve: AppCurves.enter,
            width: constraints.maxWidth * progress,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppRadius.pill),
              ),
            ),
          ),
        );
      },
    );
  }
}
