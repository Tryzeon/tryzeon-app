import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatSkeletonBubble extends StatelessWidget {
  const ChatSkeletonBubble({super.key});

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    final colorEdge = theme.colorScheme.surfaceContainer;
    final colorMid = theme.colorScheme.surfaceContainerHigh;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.card),
            topRight: Radius.circular(AppRadius.card),
            bottomLeft: Radius.zero,
            bottomRight: Radius.circular(AppRadius.card),
          ),
        ),
        child: Skeletonizer(
          enabled: true,
          effect: ShimmerEffect(
            baseColor: colorEdge,
            highlightColor: colorMid,
            duration: const Duration(milliseconds: 1400),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Bone(width: 200, height: AppSpacing.smMd),
              SizedBox(height: AppSpacing.sm),
              Bone(width: 160, height: AppSpacing.smMd),
              SizedBox(height: AppSpacing.sm),
              Bone(width: 180, height: AppSpacing.smMd),
            ],
          ),
        ),
      ),
    );
  }
}
