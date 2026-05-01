import 'dart:io';
import 'package:typed_result/typed_result.dart';
import '../../../../../core/error/failures.dart';
import '../entities/wardrobe_item.dart';

abstract class WardrobeRepository {
  Future<Result<List<WardrobeItem>, Failure>> getWardrobeItems({
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> uploadWardrobeItem(final CreateWardrobeItemParams params);

  Future<Result<void, Failure>> deleteWardrobeItem(final WardrobeItem item);

  Future<Result<WardrobeItem, Failure>> updateWardrobeItemTags({
    required final WardrobeItem item,
    required final List<String> tags,
  });

  Future<Result<File, Failure>> getWardrobeItemImage(final String imagePath);
}
