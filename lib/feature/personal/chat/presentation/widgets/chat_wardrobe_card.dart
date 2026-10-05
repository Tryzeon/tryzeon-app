import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_frame.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/actions/wardrobe_outfit_actions.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class ChatWardrobeCard extends ConsumerWidget {
  const ChatWardrobeCard({super.key, required this.item});

  final WardrobeItem item;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final tagLine = item.tags.take(2).join(' · ');

    return ChatCardFrame(
      tag: '衣櫃',
      image: _WardrobeImage(imagePath: item.imagePath),
      onTap: () => context.push(AppRoutes.personalWardrobeItemPath(item.id)),
      onTryon: () =>
          triggerOutfitTryon(context, ref, [outfitPieceFromWardrobeItem(item)]),
      details: [
        Text(
          item.garmentType.displayName,
          style: textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (tagLine.isNotEmpty)
          Text(
            tagLine,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _WardrobeImage extends ConsumerWidget {
  const _WardrobeImage({required this.imagePath});

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
