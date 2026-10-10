import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// The frosted surface for controls that float over a photo: readable on any
/// image without leaning on a scrim, and flat — a hairline instead of a shadow.
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: AppRadius.pillAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: AppOpacity.overlay),
            border: Border.all(
              color: colorScheme.onPrimary.withValues(alpha: AppOpacity.medium),
              width: AppStroke.thin,
            ),
            borderRadius: AppRadius.pillAll,
          ),
          child: child,
        ),
      ),
    );
  }
}
