import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_rating_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_rating.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_rating_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryonRatingRepositoryImpl implements TryonRatingRepository {
  TryonRatingRepositoryImpl({
    required final TryonRatingRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final TryonRatingRemoteDataSource _remoteDataSource;

  @override
  Future<Result<void, Failure>> rate({
    required final String tryonId,
    required final TryonRating? rating,
  }) async {
    try {
      if (rating == null) {
        await _remoteDataSource.delete(tryonId);
      } else {
        await _remoteDataSource.upsert(tryonId: tryonId, rating: rating.value);
      }
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Try-on rating failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
