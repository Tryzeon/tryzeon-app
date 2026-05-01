import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class TryOnMoreOptionsButton extends StatelessWidget {
  const TryOnMoreOptionsButton({
    super.key,
    required this.currentTryonIndex,
    required this.customAvatarIndex,
    required this.onDownload,
    required this.onToggleAvatar,
    required this.onDelete,
  });

  final int currentTryonIndex;
  final int? customAvatarIndex;
  final VoidCallback onDownload;
  final VoidCallback onToggleAvatar;
  final VoidCallback onDelete;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return IconButton(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: Colors.white,
        size: 24,
        shadows: [Shadow(color: Colors.black38, blurRadius: 8.0, offset: Offset(0, 2))],
      ),
      splashColor: Colors.white.withValues(alpha: 0.1),
      highlightColor: Colors.white.withValues(alpha: 0.1),
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
                  subtitle: Text('儲存到相簿', style: subtitleStyle),
                  onTap: () {
                    Navigator.pop(context);
                    onDownload();
                  },
                ),
                ListTile(
                  leading: Icon(
                    customAvatarIndex == currentTryonIndex
                        ? Icons.person_off_outlined
                        : Icons.person_outline_rounded,
                  ),
                  title: Text(
                    customAvatarIndex == currentTryonIndex ? '取消我的形象' : '設為我的形象',
                  ),
                  subtitle: Text(
                    customAvatarIndex == currentTryonIndex
                        ? '取消使用此照片作為試穿形象'
                        : '使用此照片作為試穿形象',
                    style: subtitleStyle,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onToggleAvatar();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('刪除此試穿'),
                  subtitle: Text('移除這張試穿照片', style: subtitleStyle),
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
