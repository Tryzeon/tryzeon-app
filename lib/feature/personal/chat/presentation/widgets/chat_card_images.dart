import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_style.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class ChatProductImage extends StatelessWidget {
  const ChatProductImage({super.key, required this.product});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = product.colors.coverImageUrl;
    if (imageUrl == null) {
      return Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant);
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: product.colors.coverImagePath,
      fit: BoxFit.cover,
      placeholder: (final _, final _) => const SizedBox.shrink(),
      errorWidget: (final _, final _, final _) => Icon(
        Icons.broken_image_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// A cutout keeps its original canvas, so `cover` frames it like the photo it
/// was cut from, with the card's backdrop showing through the transparency.
class ChatWardrobeImage extends ConsumerWidget {
  const ChatWardrobeImage({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return ref
        .watch(wardrobeItemImageProvider(imagePath))
        .when(
          data: (final file) => Image.file(file, fit: BoxFit.cover),
          loading: () => const SizedBox.shrink(),
          error: (final _, final _) => Icon(
            Icons.image_not_supported_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        );
  }
}

/// A label laid on a photo. The stroke keeps the white pill visible on a white
/// product shot or the cutout backdrop.
class ChatImageTag extends StatelessWidget {
  const ChatImageTag(this.label, {super.key});

  const ChatImageTag.wardrobe({super.key}) : label = '衣櫃';

  final String label;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: colorScheme.onSurface.withValues(
            alpha: ChatCardStyle.tagStrokeAlpha,
          ),
          width: AppStroke.thin,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Pins a tag to a photo's top-left corner, bounded by the photo's far edge: a
/// highlight is model-written and only the prompt bounds its length, so a long
/// one ends in an ellipsis instead of running off the photo.
class ChatImageTagSlot extends StatelessWidget {
  const ChatImageTagSlot({super.key, required this.tag});

  final ChatImageTag tag;

  @override
  Widget build(final BuildContext context) {
    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Align(alignment: Alignment.topLeft, child: tag),
    );
  }
}

/// Words laid over a photo's foot on a gradient that deepens under them. The
/// scrim never catches a tap, so a cell beneath it stays tappable.
class ChatImageScrim extends StatelessWidget {
  const ChatImageScrim({super.key, required this.child});

  final Widget child;

  static const double _fadeEnd = 0.8;
  static const int _fadeSteps = 12;

  @override
  Widget build(final BuildContext context) {
    final scrim = Theme.of(context).colorScheme.scrim;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [
                    for (var i = 0; i <= _fadeSteps; i++)
                      _fadeEnd * i / _fadeSteps,
                  ],
                  colors: [
                    for (var i = 0; i <= _fadeSteps; i++)
                      scrim.withValues(
                        alpha:
                            ChatCardStyle.scrimAlpha *
                            Curves.easeInOut.transform(i / _fadeSteps),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
