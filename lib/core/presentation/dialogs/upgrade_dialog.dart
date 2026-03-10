import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpgradeDialog {
  static void show(
    final BuildContext context, {
    final String? title,
    final String? content,
  }) {
    showDialog<void>(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: Text(title ?? '已達使用上限'),
        content: Text(content ?? '您的使用次數已達上限\n升級至更高方案以獲得更多額度！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close the dialog
              context.push('/personal/settings/subscription');
            },
            child: const Text('前往訂閱'),
          ),
        ],
      ),
    );
  }
}
