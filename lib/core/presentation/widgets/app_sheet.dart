import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// [content] wraps the body in a scroll view and hugs it; [tall] fixes the
/// sheet at [tallFraction] of the screen and expects a body that scrolls
/// itself, such as a `ListView`.
enum AppSheetHeight {
  content,
  tall;

  static const double tallFraction = 0.7;
}

Future<T?> showAppSheet<T>({
  required final BuildContext context,
  required final WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: builder,
  );
}

class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    this.title,
    this.icon,
    this.onBack,
    this.trailing,
    required this.body,
    this.footer,
    this.height = AppSheetHeight.content,
  });

  final String? title;
  final IconData? icon;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget body;
  final Widget? footer;
  final AppSheetHeight height;

  @override
  Widget build(final BuildContext context) {
    final title = this.title;
    final footer = this.footer;

    final content = SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            _AppSheetHeader(
              title: title,
              icon: icon,
              onBack: onBack,
              trailing: trailing,
            ),
          switch (height) {
            AppSheetHeight.content => Flexible(
              child: SingleChildScrollView(child: body),
            ),
            AppSheetHeight.tall => Expanded(child: body),
          },
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: footer,
            ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: switch (height) {
        AppSheetHeight.content => content,
        AppSheetHeight.tall => LayoutBuilder(
          builder: (final context, final constraints) => SizedBox(
            height: math.min(
              MediaQuery.sizeOf(context).height * AppSheetHeight.tallFraction,
              constraints.maxHeight,
            ),
            child: content,
          ),
        ),
      },
    );
  }
}

class _AppSheetHeader extends StatelessWidget {
  const _AppSheetHeader({
    required this.title,
    this.icon,
    this.onBack,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) {
    final icon = this.icon;
    final onBack = this.onBack;
    final trailing = this.trailing;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        onBack == null ? AppSpacing.lg : AppSpacing.xs,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: '返回',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            )
          else if (icon != null) ...[
            Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: AppSpacing.smMd),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
