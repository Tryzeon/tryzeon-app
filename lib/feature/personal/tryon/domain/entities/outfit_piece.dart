import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';

part 'outfit_piece.freezed.dart';

/// Carries plain ids, paths and urls so the tryon feature never depends on
/// wardrobe or shop entities.
@freezed
sealed class OutfitPiece with _$OutfitPiece {
  const factory OutfitPiece.wardrobe({
    required final String wardrobeItemId,
    required final String imagePath,
    required final GarmentType garmentType,
  }) = OutfitPieceWardrobe;

  const factory OutfitPiece.product({
    required final String productId,
    required final String name,
    required final String imageUrl,
    required final GarmentType garmentType,
    final String? sizeId,
  }) = OutfitPieceProduct;

  const factory OutfitPiece.local({required final String path}) = OutfitPieceLocal;

  const OutfitPiece._();

  String get id => switch (this) {
    OutfitPieceWardrobe(:final wardrobeItemId) => wardrobeItemId,
    OutfitPieceProduct(:final productId) => productId,
    OutfitPieceLocal(:final path) => path,
  };

  /// Null for a local photo: its bytes are read when the try-on launches.
  TryonGarment? get garment => switch (this) {
    OutfitPieceWardrobe(:final wardrobeItemId) => TryonGarment.wardrobe(
      wardrobeItemId: wardrobeItemId,
    ),
    OutfitPieceProduct(:final productId, :final sizeId) => TryonGarment.product(
      productId: productId,
      sizeId: sizeId,
    ),
    OutfitPieceLocal() => null,
  };

  /// An unknown wardrobe (still loading) counts as live: nothing is dropped on
  /// a guess. Only wardrobe pieces can go stale.
  bool isLiveIn(final Set<String>? wardrobeIds) =>
      this is! OutfitPieceWardrobe || (wardrobeIds?.contains(id) ?? true);
}
