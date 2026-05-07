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
                  leading: Icon(Icons.download_rounded, color: colorScheme.onSurface),
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
                    color: colorScheme.onSurface,
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
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.onSurface,
                  ),
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
