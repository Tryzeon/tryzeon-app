import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

import '../entities/wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';
import '../services/wardrobe_image_storage.dart';

class DeleteWardrobeItem {
  DeleteWardrobeItem({
    required final WardrobeRepository repository,
    required final WardrobeImageStorage imageStorage,
  }) : _repository = repository,
       _imageStorage = imageStorage;

  final WardrobeRepository _repository;
  final WardrobeImageStorage _imageStorage;

  Future<Result<void, Failure>> call(final WardrobeItem item) async {
    final deleted = await _repository.deleteWardrobeItem(item.id);
    if (deleted.isFailure) return deleted;

    final imageDeleted = await _imageStorage.delete(item.imagePath);
    if (imageDeleted.isFailure) {
      AppLogger.warning(
        'Failed to delete wardrobe image ${item.imagePath}',
        imageDeleted.getError(),
      );
    }
    return const Ok(null);
  }
}
