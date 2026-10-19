import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/usage_quota/data/dtos/usage_quota_dto.dart';
import 'package:tryzeon/feature/common/usage_quota/data/mappers/usage_quota_mappr.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/usage/data/datasources/usage_quota_remote_datasource.dart';
import 'package:tryzeon/feature/personal/usage/domain/repositories/usage_quota_repository.dart';
import 'package:typed_result/typed_result.dart';

class UsageQuotaRepositoryImpl implements UsageQuotaRepository {
  UsageQuotaRepositoryImpl({
    required final UsageQuotaRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final UsageQuotaRemoteDataSource _remoteDataSource;
  static const _mappr = UsageQuotaMappr();

  @override
  Future<Result<UsageQuota, Failure>> getUsageQuota() async {
    try {
      return Ok(
        _mappr.convert<UsageQuotaDto, UsageQuota>(
          await _remoteDataSource.getUsageQuota(),
        ),
      );
    } catch (e, stack) {
      AppLogger.error('Failed to load usage quota', e, stack);
      return Err(mapExceptionToFailure(e));
    }
  }
}
