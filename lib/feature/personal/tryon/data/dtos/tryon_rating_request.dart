import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_dislike_reason.dart';

part 'tryon_rating_request.g.dart';

enum TryonRating { like, dislike }

/// Keeps json_serializable's default `includeIfNull: true`: an upsert leaves
/// unsent columns as they were, so a switch to a like must send [reason] and
/// [comment] as null to clear them.
@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class TryonRatingRequest {
  const TryonRatingRequest({
    required this.tryonGenerationId,
    required this.rating,
    this.reason,
    this.comment,
  });

  final String tryonGenerationId;
  final TryonRating rating;
  final TryonDislikeReason? reason;
  final String? comment;

  Map<String, dynamic> toJson() => _$TryonRatingRequestToJson(this);
}
