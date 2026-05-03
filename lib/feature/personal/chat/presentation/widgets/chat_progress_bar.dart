import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatProgressBar extends StatelessWidget {
  const ChatProgressBar({
    super.key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
  });

  final int currentQuestionIndex;
  final int totalQuestions;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalQuestions > 0
        ? (currentQuestionIndex / totalQuestions).clamp(0.0, 1.0)
        : 0.0;

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
            height: double.infinity,
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
