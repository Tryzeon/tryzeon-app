import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

WardrobeItem wardrobeItem(
  final String id, [
  final GarmentType type = GarmentType.top,
]) => WardrobeItem(
  id: id,
  imagePath: '$id.jpg',
  garmentType: type,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

OutfitPiece wardrobePiece(
  final String id, [
  final GarmentType type = GarmentType.top,
]) => OutfitPiece.wardrobe(
  wardrobeItemId: id,
  imagePath: '$id.jpg',
  garmentType: type,
);

class FakeWardrobeItems extends WardrobeItemsNotifier {
  FakeWardrobeItems(this._initial);
  final List<WardrobeItem> _initial;

  @override
  Future<List<WardrobeItem>> build() async => _initial;

  void setItems(final List<WardrobeItem> items) => state = AsyncData(items);
}
