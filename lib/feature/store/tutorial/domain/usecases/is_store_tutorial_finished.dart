import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/tutorial/domain/repositories/store_tutorial_repository.dart';
import 'package:typed_result/typed_result.dart';

class IsStoreTutorialFinished {
  IsStoreTutorialFinished(this._repository);

  final StoreTutorialRepository _repository;

  Future<Result<bool, Failure>> call(final String storeId) =>
      _repository.isFinished(storeId);
}
