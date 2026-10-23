import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/tutorial/data/datasources/store_tutorial_local_datasource.dart';
import 'package:tryzeon/feature/store/tutorial/domain/repositories/store_tutorial_repository.dart';
import 'package:typed_result/typed_result.dart';

class StoreTutorialRepositoryImpl implements StoreTutorialRepository {
  StoreTutorialRepositoryImpl(this._local);

  final StoreTutorialLocalDataSource _local;

  @override
  Future<Result<bool, Failure>> isFinished(final String storeId) async {
    try {
      return Ok(await _local.isFinished(storeId));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read store tutorial state', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> finish(final String storeId) async {
    try {
      await _local.finish(storeId);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to mark the store tutorial finished',
        e,
        stackTrace,
      );
      return Err(mapExceptionToFailure(e));
    }
  }
}
