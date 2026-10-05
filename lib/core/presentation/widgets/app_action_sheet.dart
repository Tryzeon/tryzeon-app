import 'package:flutter/material.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class AppMenuAction {
  const AppMenuAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
}

Future<void> showAppActionSheet(
  final BuildContext context, {
  required final List<AppMenuAction> actions,
  final String? title,
  final String? hint,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (final context) => AppSheet(
      title: title,
      body: _ActionList(actions: actions, hint: hint),
    ),
  );
}

class _ActionList extends StatelessWidget {
  const _ActionList({required this.actions, this.hint});

  final List<AppMenuAction> actions;
  final String? hint;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hint = this.hint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (final (index, action) in actions.indexed) ...[
          if (action.isDestructive &&
              index > 0 &&
              !actions[index - 1].isDestructive)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
          ListTile(
            leading: Icon(
              action.icon,
              color: action.isDestructive ? colorScheme.error : null,
            ),
            title: Text(
              action.title,
              style: action.isDestructive
                  ? TextStyle(color: colorScheme.error)
                  : null,
            ),
            onTap: () {
              Navigator.pop(context);
              action.onTap();
            },
          ),
        ],
      ],
    );
  }
}
