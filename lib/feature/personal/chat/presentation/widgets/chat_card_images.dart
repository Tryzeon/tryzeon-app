import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/glass_surface.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class ChatProductImage extends StatelessWidget {
  const ChatProductImage({super.key, required this.product});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (product.imageUrls.isEmpty) {
      return Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant);
    }
    return CachedNetworkImage(
      imageUrl: product.imageUrls.first,
      cacheKey: product.imagePaths.isNotEmpty ? product.imagePaths.first : null,
      fit: BoxFit.cover,
      placeholder: (final _, final _) => const SizedBox.shrink(),
      errorWidget: (final _, final _, final _) => Icon(
        Icons.broken_image_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// A wardrobe photo is a cutout, so it is set whole on its frame's surface
/// rather than cropped to fill it the way a product photo is.
class ChatWardrobeImage extends ConsumerWidget {
  const ChatWardrobeImage({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return ref
        .watch(wardrobeItemImageProvider(imagePath))
        .when(
          data: (final file) => Padding(
            padding: const EdgeInsets.all(AppSpacing.smMd),
            child: Image.file(file, fit: BoxFit.contain),
          ),
          loading: () => const SizedBox.shrink(),
          error: (final _, final _) => Icon(
            Icons.image_not_supported_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        );
  }
}

/// A label laid on a photo: the same frosted glass as the try-on pill, cut
/// square so it reads as a tag rather than a control.
class ChatImageTag extends StatelessWidget {
  const ChatImageTag(this.label, {super.key});

  const ChatImageTag.wardrobe({super.key}) : label = '你的衣櫃';

  final String label;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      borderRadius: AppRadius.tagAll,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

/// The line above a card's name saying where the piece comes from: a store, or
/// the wardrobe. It leads in ink so the name below can step back to muted.
class ChatSourceLine extends StatelessWidget {
  const ChatSourceLine(this.text, {super.key});

  final String text;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
