import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

import '../entities/wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';

class UploadWardrobeItem {
  UploadWardrobeItem(this._wardrobeRepository);

  final WardrobeRepository _wardrobeRepository;

  Future<Result<void, Failure>> call({
    required final CreateWardrobeItemParams params,
    required final int currentItemCount,
    required final int wardrobeLimit,
  }) async {
    if (currentItemCount >= wardrobeLimit) {
      return const Err(ValidationFailure());
    }

    return _wardrobeRepository.uploadWardrobeItem(params);
  }
}
