import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/mappers/garment_type_display.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_frame.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/actions/wardrobe_outfit_actions.dart';

class ChatWardrobeCard extends ConsumerWidget {
  const ChatWardrobeCard({super.key, required this.item, this.highlight});

  final WardrobeItem item;
  final String? highlight;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final description = [
      item.garmentType.displayName,
      ...item.tags.take(3),
    ].join(' · ');

    final label = highlight;

    return ChatCardFrame(
      image: ChatWardrobeImage(imagePath: item.imagePath),
      tag: label == null ? null : ChatImageTag(label),
      onTap: () => context.push(AppRoutes.personalWardrobeItemPath(item.id)),
      onTryon: () =>
          triggerOutfitTryon(context, ref, [outfitPieceFromWardrobeItem(item)]),
      details: [
        const ChatSourceLine('你的衣櫃'),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          description,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.neutral40,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
