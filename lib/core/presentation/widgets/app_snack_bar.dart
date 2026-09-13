import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Silent result feedback (e.g. "saved to album"). Hosted by the calling
/// page's Scaffold (the tab shells provide their own ScaffoldMessenger), so it
/// lifts above the page FAB when present and otherwise above the floating nav
/// bar, which the framework's safe-area padding doesn't account for. Failures
/// should use `TopNotification`.
class AppSnackBar {
  static void show(
    final BuildContext context, {
    required final String message,
    final String? actionLabel,
    final VoidCallback? onAction,
  }) {
    final liftsItself = Scaffold.maybeOf(context)?.hasFloatingActionButton ?? false;

    final navBarOffset = liftsItself ? 0.0 : AppSpacing.bottomNavBarOverlap;

    final hasAction = actionLabel != null && onAction != null;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: hasAction
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,

        persist: false,
        duration: hasAction ? const Duration(seconds: 6) : const Duration(seconds: 4),
        margin: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.sm + navBarOffset,
        ),
      ),
    );
  }
}
