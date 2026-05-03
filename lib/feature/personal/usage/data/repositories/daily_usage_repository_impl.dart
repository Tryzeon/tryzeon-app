import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/usage/data/datasources/daily_usage_remote_datasource.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/usage/domain/repositories/daily_usage_repository.dart';
import 'package:typed_result/typed_result.dart';

class DailyUsageRepositoryImpl implements DailyUsageRepository {
  DailyUsageRepositoryImpl({required final DailyUsageRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final DailyUsageRemoteDataSource _remoteDataSource;

  @override
  Future<Result<DailyUsage, Failure>> getTodayUsage() async {
    try {
      final model = await _remoteDataSource.getTodayUsage();
      return Ok(model.toEntity());
    } catch (e, stack) {
      AppLogger.error('Failed to load daily usage', e, stack);
      return Err(mapExceptionToFailure(e));
    }
  }
}
