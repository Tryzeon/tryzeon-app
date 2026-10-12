import 'dart:io';
import 'package:typed_result/typed_result.dart';
import '../../../../../core/error/failures.dart';
import '../entities/new_wardrobe_item.dart';
import '../entities/wardrobe_item.dart';
import '../entities/wardrobe_item_update.dart';

abstract class WardrobeRepository {
  Future<Result<List<WardrobeItem>, Failure>> getWardrobeItems({
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> createWardrobeItem(final NewWardrobeItem item);

  Future<Result<void, Failure>> deleteWardrobeItem(final String id);

  Future<Result<WardrobeItem, Failure>> updateWardrobeItem(
    final String id,
    final WardrobeItemUpdate update,
  );

  Future<Result<File, Failure>> getWardrobeItemImage(final String imagePath);
}
