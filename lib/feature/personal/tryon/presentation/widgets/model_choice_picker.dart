import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';

class ModelChoicePicker extends StatelessWidget {
  const ModelChoicePicker({
    super.key,
    required this.presets,
    required this.onPresetSelected,
    required this.onUploadOwnPhoto,
  });

  static const double _maxTileWidth = 168;

  final List<PresetAvatar> presets;
  final ValueChanged<PresetAvatar> onPresetSelected;
  final VoidCallback onUploadOwnPhoto;

  @override
  Widget build(final BuildContext context) {
    final tiles = [
      for (final preset in presets)
        ModelChoiceTile(
          image: AssetImage(preset.assetPath),
          label: preset.label,
          onTap: () => onPresetSelected(preset),
        ),
      ModelChoiceTile(
        image: const AssetImage(AppConstants.ownPhotoPlaceholder),
        label: '上傳自己的照片',
        onTap: onUploadOwnPhoto,
      ),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: _maxTileWidth * tiles.length + AppSpacing.md * (tiles.length - 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, tile) in tiles.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: tile),
          ],
        ],
      ),
    );
  }
}

class ModelChoiceTile extends StatelessWidget {
  const ModelChoiceTile({
    super.key,
    required this.image,
    required this.label,
    required this.onTap,
  });

  final ImageProvider image;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    const ratio = AppConstants.avatarAspectRatio;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: ratio.x / ratio.y,
              child: Ink.image(image: image, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(label, style: theme.textTheme.titleSmall),
            ),
          ],
        ),
      ),
    );
  }
}
