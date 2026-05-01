import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

import '../entities/wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';

class UpdateWardrobeItemTags {
  UpdateWardrobeItemTags(this._repository);

  final WardrobeRepository _repository;

  Future<Result<WardrobeItem, Failure>> call({
    required final WardrobeItem item,
    required final List<String> tags,
  }) {
    return _repository.updateWardrobeItemTags(item: item, tags: tags);
  }
}
