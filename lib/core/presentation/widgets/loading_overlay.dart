import 'package:flutter/material.dart';

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
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
