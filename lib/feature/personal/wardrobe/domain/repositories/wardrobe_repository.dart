import 'dart:io';
import 'package:typed_result/typed_result.dart';
import '../../../../../core/error/failures.dart';
import '../entities/wardrobe_category.dart';
import '../entities/wardrobe_item.dart';

abstract class WardrobeRepository {
  Future<Result<List<WardrobeItem>, Failure>> getWardrobeItems({
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> uploadWardrobeItem({
    required final File image,
    required final WardrobeCategory category,
    final List<String> tags = const [],
  });

  Future<Result<void, Failure>> deleteWardrobeItem(final WardrobeItem item);

  Future<Result<File, Failure>> getWardrobeItemImage(final String imagePath);
}
