import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_rating.dart';
import 'package:typed_result/typed_result.dart';

abstract class TryonRatingRepository {
  /// A null [rating] clears the try-on's rating.
  Future<Result<void, Failure>> rate({
    required final String tryonId,
    required final TryonRating? rating,
  });
}
