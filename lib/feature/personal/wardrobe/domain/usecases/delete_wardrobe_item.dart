import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';
import '../entities/wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';

class DeleteWardrobeItem {
  DeleteWardrobeItem(this._repository);
  final WardrobeRepository _repository;

  Future<Result<void, Failure>> call(final WardrobeItem item) =>
      _repository.deleteWardrobeItem(item);
}
