import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_dislike_reason.dart';

part 'tryon_feedback.freezed.dart';

@freezed
sealed class TryonFeedback with _$TryonFeedback {
  const factory TryonFeedback.like() = TryonLike;

  /// Explained by a picked [reason] or by a typed [comment], if at all.
  const factory TryonFeedback.dislike({
    final TryonDislikeReason? reason,
    final String? comment,
  }) = TryonDislike;
}
