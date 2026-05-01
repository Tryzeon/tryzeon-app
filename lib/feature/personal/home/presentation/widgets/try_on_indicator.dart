import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class TryOnIndicator extends StatelessWidget {
  const TryOnIndicator({
    super.key,
    required this.currentTryonIndex,
    required this.tryonImagesCount,
  });

  final int currentTryonIndex;
  final int tryonImagesCount;

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(tryonImagesCount, (final index) {
        final isSelected = currentTryonIndex == index;
        return AnimatedContainer(
          duration: AppDuration.slow,
          curve: AppCurves.standard,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          width: isSelected ? 20.0 : 12.0,
          height: 2.0,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(0, 1)),
            ],
          ),
        );
      }),
    );
  }
}
