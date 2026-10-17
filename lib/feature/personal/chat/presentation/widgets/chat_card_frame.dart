import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_style.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

/// One card for a store product and a wardrobe item alike: the photo is the
/// card and the words sit on a scrim over its foot.
class ChatCardFrame extends HookWidget {
  const ChatCardFrame({
    super.key,
    required this.image,
    required this.onTap,
    required this.onTryon,
    required this.source,
    required this.name,
    required this.value,
    this.valueMuted = false,
    this.highlight,
  });

  final Widget image;
  final VoidCallback onTap;
  final VoidCallback onTryon;
  final String source;
  final String name;
  final String value;
  final bool valueMuted;
  final String? highlight;

  static const double _pressedScale = 0.97;

  @override
  Widget build(final BuildContext context) {
    final pressed = useState(false);
    final label = highlight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onTapDown: (final _) => pressed.value = true,
      onTapUp: (final _) => pressed.value = false,
      onTapCancel: () => pressed.value = false,
      child: AnimatedScale(
        scale: pressed.value ? _pressedScale : 1,
        duration: AppDuration.quick,
        curve: AppCurves.standard,
        child: AspectRatio(
          aspectRatio: ChatCardStyle.pickAspectRatio,
          child: ClipRRect(
            borderRadius: ChatCardStyle.radius,
            child: ColoredBox(
              color: ChatCardStyle.cutoutBackdrop,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _Details(
                      source: source,
                      name: name,
                      value: value,
                      valueMuted: valueMuted,
                      onTryon: onTryon,
                    ),
                  ),
                  if (label != null) ChatImageTagSlot(tag: ChatImageTag(label)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.source,
    required this.name,
    required this.value,
    required this.valueMuted,
    required this.onTryon,
  });

  final String source;
  final String name;
  final String value;
  final bool valueMuted;
  final VoidCallback onTryon;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final onImage = colorScheme.onPrimary;
    final onImageMuted = onImage.withValues(
      alpha: ChatCardStyle.mutedTextAlpha,
    );

    return ChatImageScrim(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.smMd,
          AppSpacing.lg,
          AppSpacing.smMd,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              source,
              style: textTheme.bodySmall?.copyWith(
                color: onImageMuted,
                letterSpacing: 0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                name,
                style: textTheme.bodyMedium?.copyWith(
                  color: onImage,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: valueMuted
                        ? textTheme.bodySmall?.copyWith(color: onImageMuted)
                        : textTheme.bodyMedium?.copyWith(
                            color: onImage,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TryonFab(label: '試穿', compact: true, onTap: onTryon),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
