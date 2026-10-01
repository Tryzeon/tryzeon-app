import 'dart:io';
import 'package:typed_result/typed_result.dart';
import '../../../../../core/error/failures.dart';
import '../../../../common/garment_type/domain/entities/garment_type.dart';
import '../entities/wardrobe_item.dart';

abstract class WardrobeRepository {
  Future<Result<List<WardrobeItem>, Failure>> getWardrobeItems({
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> createWardrobeItem({
    required final String id,
    required final String imagePath,
    required final GarmentType garmentType,
    required final List<String> tags,
  });

  Future<Result<void, Failure>> deleteWardrobeItem(final String id);

  Future<Result<WardrobeItem, Failure>> updateWardrobeItem({
    required final String id,
    final GarmentType? garmentType,
    final List<String>? tags,
  });

  Future<Result<File, Failure>> getWardrobeItemImage(final String imagePath);
}
