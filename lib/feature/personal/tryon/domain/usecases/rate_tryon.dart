import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_rating_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'rate_tryon.freezed.dart';

@freezed
sealed class RateTryonParams with _$RateTryonParams {
  const factory RateTryonParams({
    required final String tryonId,
    required final TryonFeedback? feedback,
  }) = _RateTryonParams;
}

class RateTryon {
  RateTryon({required final TryonRatingRepository ratingRepository})
    : _ratingRepository = ratingRepository;

  final TryonRatingRepository _ratingRepository;

  Future<Result<void, Failure>> call(final RateTryonParams params) {
    return _ratingRepository.rate(
      tryonId: params.tryonId,
      feedback: params.feedback,
    );
  }
}
