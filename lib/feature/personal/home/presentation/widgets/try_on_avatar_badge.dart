import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Floating badge shown on the photo when the current try-on result is set
/// as the user's custom try-on avatar. Provides persistent state feedback so
/// the toggle action in the more-options sheet can stay silent.
class TryOnAvatarBadge extends StatelessWidget {
  const TryOnAvatarBadge({super.key, required this.isVisible});

  final bool isVisible;

  @override
  Widget build(final BuildContext context) {
    return AnimatedScale(
      scale: isVisible ? 1.0 : 0.0,
      duration: AppDuration.standard,
      curve: AppCurves.emphasized,
      child: const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primary,
        child: Icon(
          Icons.star_rounded,
          color: AppColors.onPrimary,
          size: 20,
        ),
      ),
    );
  }
}
