import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';

class UpgradeDialog {
  static void show(
    final BuildContext context, {
    final String? title,
    final String? content,
  }) {
    showAdaptiveDialog<void>(
      context: context,
      builder: (final ctx) => AlertDialog.adaptive(
        title: Text(title ?? '已達使用上限'),
        content: Text(content ?? '您的使用次數已達上限\n升級至更高方案以獲得更多額度！'),
        actions: [
          _action(ctx, label: '取消', onPressed: () => Navigator.pop(ctx)),
          _action(
            ctx,
            label: '前往訂閱',
            isDefault: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.personalSubscription);
            },
          ),
        ],
      ),
    );
  }

  static Widget _action(
    final BuildContext context, {
    required final String label,
    required final VoidCallback onPressed,
    final bool isDefault = false,
  }) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoDialogAction(
        isDefaultAction: isDefault,
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return isDefault
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
