import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';
import '../entities/wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';

class GetWardrobeItems {
  GetWardrobeItems(this._repository);
  final WardrobeRepository _repository;

  Future<Result<List<WardrobeItem>, Failure>> call({final bool forceRefresh = false}) =>
      _repository.getWardrobeItems(forceRefresh: forceRefresh);
}
