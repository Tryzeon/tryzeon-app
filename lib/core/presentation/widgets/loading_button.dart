import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

enum _LoadingButtonVariant { filled, text }

class LoadingButton extends StatelessWidget {
  const LoadingButton.filled({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
  }) : _variant = _LoadingButtonVariant.filled;

  const LoadingButton.text({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
  }) : _variant = _LoadingButtonVariant.text;

  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final _LoadingButtonVariant _variant;

  @override
  Widget build(final BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final colorScheme = Theme.of(context).colorScheme;

    return switch (_variant) {
      _LoadingButtonVariant.filled => FilledButton(
        onPressed: effectiveOnPressed,
        child: isLoading
            ? _Spinner(size: AppSpacing.mdLg, color: colorScheme.onPrimary)
            : child,
      ),
      _LoadingButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        child: isLoading ? const _Spinner(size: AppSpacing.md) : child,
      ),
    };
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.size, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(color: color, strokeWidth: AppStroke.regular),
    );
  }
}
