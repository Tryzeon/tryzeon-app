import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';

const double _frameIconSize = 32;

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
          frame: _PresetFrame(preset: preset),
          title: preset.label,
          caption: '立即開始試穿',
          onTap: () => onPresetSelected(preset),
        ),
      ModelChoiceTile(
        frame: const _UploadFrame(),
        title: '上傳全身照',
        caption: '穿在自己身上',
        onTap: onUploadOwnPhoto,
      ),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth:
            _maxTileWidth * tiles.length + AppSpacing.md * (tiles.length - 1),
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
    required this.frame,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final Widget frame;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    const ratio = AppConstants.avatarAspectRatio;

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(aspectRatio: ratio.x / ratio.y, child: frame),
            const SizedBox(height: AppSpacing.smMd),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: AppRadius.cardAll,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetFrame extends ConsumerWidget {
  const _PresetFrame({required this.preset});

  final PresetAvatar preset;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final file = ref.watch(presetAvatarFileProvider(preset)).value;
    final placeholder = Center(
      child: Icon(
        Icons.person_outline_rounded,
        size: _frameIconSize,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: file == null
          ? placeholder
          : Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (final _, final _, final _) => placeholder,
            ),
    );
  }
}

class _UploadFrame extends StatelessWidget {
  const _UploadFrame();

  static const List<double> _dashPattern = [6, 4];

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(AppRadius.card),
        padding: EdgeInsets.zero,
        strokeWidth: AppStroke.regular,
        color: colorScheme.outline,
        dashPattern: _dashPattern,
        stackFit: StackFit.expand,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: ColoredBox(
          color: colorScheme.surfaceContainerLow,
          child: Center(
            child: Icon(
              Icons.add_a_photo_outlined,
              size: _frameIconSize,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
