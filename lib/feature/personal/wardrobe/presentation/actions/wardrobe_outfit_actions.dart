import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

OutfitPiece outfitPieceFromWardrobeItem(final WardrobeItem item) => OutfitPiece.wardrobe(
  wardrobeItemId: item.id,
  imagePath: item.imagePath,
  garmentType: item.garmentType,
);
