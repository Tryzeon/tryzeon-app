import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetWardrobeItems {
  GetWardrobeItems(this._repository);
  final WardrobeRepository _repository;

  Future<Result<List<WardrobeItem>, Failure>> call({
    final bool forceRefresh = false,
  }) => _repository.getWardrobeItems(forceRefresh: forceRefresh);
}
