import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_thumbnail.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class TryonOutfitRail extends ConsumerWidget {
  const TryonOutfitRail({super.key, required this.pieces});

  final List<OutfitPiece> pieces;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final wardrobeIds = ref.watch(wardrobeItemIdsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < pieces.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _RailTile(piece: pieces[i], isRemoved: !pieces[i].isLiveIn(wardrobeIds)),
        ],
      ],
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({required this.piece, required this.isRemoved});

  static const double _size = 52;
  static const double _badgeSize = 20;

  final OutfitPiece piece;
  final bool isRemoved;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final String? route = switch (piece) {
      OutfitPieceWardrobe(:final wardrobeItemId) when !isRemoved =>
        AppRoutes.personalWardrobeItemPath(wardrobeItemId),
      OutfitPieceProduct(:final productId) => AppRoutes.personalShopProductPath(
        productId,
      ),
      _ => null,
    };

    return Opacity(
      opacity: isRemoved ? AppOpacity.overlay : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            key: Key('outfit-rail-${piece.id}'),
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardAll,
              border: Border.all(
                color: colorScheme.onPrimary.withValues(alpha: AppOpacity.overlay),
                width: AppStroke.thin,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.cardAll,
              child: Stack(
                children: [
                  OutfitPieceThumbnail(
                    piece: piece,
                    size: _size,
                    borderRadius: BorderRadius.zero,
                  ),
                  Positioned.fill(
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: route == null ? null : () => context.push(route),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (piece is OutfitPieceProduct)
            Positioned(
              top: -AppSpacing.xs,
              right: -AppSpacing.xs,
              child: IgnorePointer(
                child: Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
