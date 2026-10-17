import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

class ChatCardFrame extends HookWidget {
  const ChatCardFrame({
    super.key,
    required this.image,
    required this.onTap,
    required this.onTryon,
    required this.details,
    this.tag,
  });

  final Widget image;
  final VoidCallback onTap;
  final VoidCallback onTryon;
  final List<Widget> details;
  final ChatImageTag? tag;

  static const double _pressedScale = 0.97;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pressed = useState(false);
    final imageTag = tag;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: AppRadius.cardAll,
                child: ColoredBox(
                  color: colorScheme.surfaceContainerLow,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      image,
                      if (imageTag != null) ChatImageTagSlot(tag: imageTag),
                      Positioned(
                        bottom: 0,
                        right: AppSpacing.sm,
                        child: TryonFab(
                          label: '試穿',
                          compact: true,
                          onTap: onTryon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.smMd),
            ...details,
          ],
        ),
      ),
    );
  }
}
