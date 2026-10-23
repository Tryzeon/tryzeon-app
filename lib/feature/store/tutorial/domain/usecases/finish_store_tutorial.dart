import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/tutorial/domain/repositories/store_tutorial_repository.dart';
import 'package:typed_result/typed_result.dart';

class FinishStoreTutorial {
  FinishStoreTutorial(this._repository);

  final StoreTutorialRepository _repository;

  Future<Result<void, Failure>> call(final String storeId) =>
      _repository.finish(storeId);
}
