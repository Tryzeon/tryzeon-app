import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/daily_usage/data/dtos/daily_usage_dto.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/data/mappers/tryon_mappr.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryonRepositoryImpl implements TryonRepository {
  TryonRepositoryImpl({required final TryonRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TryonRemoteDataSource _remoteDataSource;
  static const _mappr = TryonMappr();

  @override
  Future<Result<TryonResult, Failure>> tryon(final TryonRequest request) async {
    try {
      final response = await _remoteDataSource.tryon(
        _mappr.convert<TryonRequest, TryonFunctionRequest>(request),
      );
      return Ok(
        TryonResult(
          id: request.requestId,
          mode: request.mode,
          imageUrl: response.imageUrl,
          videoUrl: response.videoUrl,
          usage: _mappr.tryConvert<DailyUsageDto, DailyUsage>(response.usage),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Virtual try-on failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
