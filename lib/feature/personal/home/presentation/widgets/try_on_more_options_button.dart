import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class TryOnMoreOptionsButton extends StatelessWidget {
  const TryOnMoreOptionsButton({
    super.key,
    required this.isCurrentTheAvatar,
    required this.canSetAsAvatar,
    required this.onDownload,
    required this.onToggleAvatar,
    required this.onDelete,
  });

  final bool isCurrentTheAvatar;
  final bool canSetAsAvatar;
  final VoidCallback onDownload;
  final VoidCallback onToggleAvatar;
  final VoidCallback onDelete;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(Icons.more_vert_rounded, color: colorScheme.onPrimary, size: 24),
      splashColor: colorScheme.onPrimary.withValues(alpha: AppOpacity.medium),
      highlightColor: colorScheme.onPrimary.withValues(alpha: AppOpacity.medium),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          showDragHandle: true,
          builder: (final context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('下載'),
                  subtitle: const Text('儲存到相簿'),
                  onTap: () {
                    Navigator.pop(context);
                    onDownload();
                  },
                ),
                if (canSetAsAvatar)
                  ListTile(
                    leading: Icon(
                      isCurrentTheAvatar
                          ? Icons.person_off_outlined
                          : Icons.person_outline_rounded,
                    ),
                    title: Text(isCurrentTheAvatar ? '取消我的形象' : '設為我的形象'),
                    subtitle: Text(isCurrentTheAvatar ? '取消使用此照片作為試穿形象' : '使用此照片作為試穿形象'),
                    onTap: () {
                      Navigator.pop(context);
                      onToggleAvatar();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('刪除此試穿'),
                  subtitle: const Text('移除這張試穿照片'),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
