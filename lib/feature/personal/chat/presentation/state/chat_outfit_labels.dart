import 'package:collection/collection.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';

typedef OutfitPurchase = ({int count, double total});

/// Null when every piece is already in the wardrobe.
OutfitPurchase? outfitPurchase(final List<ResolvedItem> pieces) {
  final prices = [
    for (final piece in pieces.whereType<ResolvedProduct>())
      piece.product.price,
  ];
  if (prices.isEmpty) return null;
  return (count: prices.length, total: prices.sum);
}

/// "共" when every piece is for sale; "再買" when the wardrobe already covers
/// part of the look.
String outfitPurchaseCountLabel(
  final OutfitPurchase purchase,
  final int pieceCount,
) => purchase.count < pieceCount
    ? '再買 ${purchase.count} 件'
    : '共 ${purchase.count} 件';

/// Outerwear leads: it is the layer the look is seen in, and the lead cell is
/// the largest.
List<ResolvedItem> outfitCollageOrder(final List<ResolvedItem> pieces) {
  final lead = pieces.indexWhere(
    (final piece) => _garmentTypeOf(piece) == GarmentType.outerwear,
  );
  if (lead <= 0) return pieces;
  return [
    pieces[lead],
    ...pieces.whereIndexed((final i, final _) => i != lead),
  ];
}

GarmentType _garmentTypeOf(final ResolvedItem piece) => switch (piece) {
  ResolvedProduct(:final product) => product.garmentType,
  ResolvedWardrobeItem(:final item) => item.garmentType,
};
