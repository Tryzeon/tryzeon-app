import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// A reusable loading overlay widget that shows a loading indicator
/// over the child widget when isLoading is true.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({required this.isLoading, required this.child, super.key});

  final bool isLoading;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: AppOpacity.strong),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
