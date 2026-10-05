import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_thumbnail.dart';

class TryonOutfitRail extends StatelessWidget {
  const TryonOutfitRail({super.key, required this.pieces, required this.onEdit});

  final List<OutfitPiece> pieces;
  final VoidCallback onEdit;

  @override
  Widget build(final BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < pieces.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _RailTile(piece: pieces[i], onEdit: i == pieces.length - 1 ? onEdit : null),
        ],
      ],
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({required this.piece, this.onEdit});

  static const double _size = 52;

  // A hit area outside the tile never receives taps, and a larger one would
  // swallow the tile's own tap at its centre.
  static const double _editHitSize = 28;

  final OutfitPiece piece;
  final VoidCallback? onEdit;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final route = switch (piece) {
      OutfitPieceWardrobe(:final wardrobeItemId) => AppRoutes.personalWardrobeItemPath(
        wardrobeItemId,
      ),
      OutfitPieceProduct(:final productId) => AppRoutes.personalShopProductPath(
        productId,
      ),
      OutfitPieceLocal(:final path) => AppRoutes.personalHomePhotoPath(path),
    };

    final badgeIcon = switch (piece) {
      OutfitPieceWardrobe() => Icons.checkroom_outlined,
      OutfitPieceProduct() => Icons.shopping_bag_outlined,
      OutfitPieceLocal() => null,
    };

    return Stack(
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
                    child: InkWell(onTap: () => context.push(route)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (badgeIcon != null)
          Positioned(
            top: -AppSpacing.xs,
            right: -AppSpacing.xs,
            child: IgnorePointer(child: _CornerBadge(icon: badgeIcon)),
          ),
        if (onEdit case final onEdit?)
          Positioned(
            right: -AppSpacing.xs,
            bottom: -AppSpacing.xs,
            child: Tooltip(
              message: '編輯搭配',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                child: const SizedBox.square(
                  dimension: _editHitSize,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: _CornerBadge(icon: Icons.edit_outlined),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.icon});

  static const double _size = 20;

  final IconData icon;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(color: colorScheme.surface, shape: BoxShape.circle),
      child: Icon(icon, size: 12, color: colorScheme.onSurface),
    );
  }
}
