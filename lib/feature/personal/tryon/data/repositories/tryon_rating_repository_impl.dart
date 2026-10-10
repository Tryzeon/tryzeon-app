import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_rating_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
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
    required final TryonFeedback? feedback,
  }) async {
    try {
      if (feedback == null) {
        await _remoteDataSource.delete(tryonId);
      } else {
        final (rating, reason, comment) = switch (feedback) {
          TryonLike() => ('like', null, null),
          TryonDislike(:final reason, :final comment) => (
            'dislike',
            reason?.value,
            comment,
          ),
        };
        await _remoteDataSource.upsert(
          tryonId: tryonId,
          rating: rating,
          reason: reason,
          comment: comment,
        );
      }
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Try-on rating failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
