import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/actions/edit_outfit.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_label.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_thumbnail.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class OutfitPiecesSheet extends ConsumerWidget {
  const OutfitPiecesSheet({super.key, required this.entry});

  final TryonGalleryEntry entry;

  static Future<bool> show(
    final BuildContext context, {
    required final TryonGalleryEntry entry,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (final _) => OutfitPiecesSheet(entry: entry),
    ).then((final edit) => edit ?? false);
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final wardrobeIds = ref.watch(wardrobeItemIdsProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('這套搭配', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final piece in entry.pieces)
              _PieceTile(piece: piece, isRemoved: !piece.isLiveIn(wardrobeIds)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: outfitHasLivePiece(wardrobeIds, entry)
                    ? () => Navigator.pop(context, true)
                    : null,
                icon: const Icon(Icons.checkroom_outlined),
                label: const Text('編輯搭配'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieceTile extends StatelessWidget {
  const _PieceTile({required this.piece, required this.isRemoved});

  final OutfitPiece piece;
  final bool isRemoved;

  @override
  Widget build(final BuildContext context) {
    final subtitle = isRemoved
        ? '已從衣櫃移除'
        : piece.name == null
        ? null
        : piece.typeLabel;

    return ListTile(
      enabled: !isRemoved,
      leading: OutfitPieceThumbnail(
        piece: piece,
        size: AppSpacing.xxl,
        borderRadius: AppRadius.buttonAll,
      ),
      title: Text(piece.label),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: switch (piece) {
        OutfitPieceWardrobe(:final wardrobeItemId) when !isRemoved => () {
          final router = GoRouter.of(context);
          Navigator.pop(context);
          router.push(AppRoutes.personalWardrobeItemPath(wardrobeItemId));
        },
        OutfitPieceProduct(:final productId) => () {
          final router = GoRouter.of(context);
          Navigator.pop(context);
          router.push(AppRoutes.personalShopProductPath(productId));
        },
        _ => null,
      },
    );
  }
}
