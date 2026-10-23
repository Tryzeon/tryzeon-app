import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

abstract class StoreTutorialRepository {
  Future<Result<bool, Failure>> isFinished(final String storeId);
  Future<Result<void, Failure>> finish(final String storeId);
}
