import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';

class TryonRatingRemoteDataSource {
  TryonRatingRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  static const _tryonGenerationId = 'tryon_generation_id';
  static const _rating = 'rating';
  static const _reason = 'reason';
  static const _comment = 'comment';

  /// Always sends [reason] and [comment], null or not: an upsert leaves unsent
  /// columns as they were, so a switch to a like would otherwise keep them.
  Future<void> upsert({
    required final String tryonId,
    required final String rating,
    required final String? reason,
    required final String? comment,
  }) async {
    await _supabase.from(AppConstants.tableTryonRatings).upsert({
      _tryonGenerationId: tryonId,
      _rating: rating,
      _reason: reason,
      _comment: comment,
    });
  }

  Future<void> delete(final String tryonId) async {
    await _supabase
        .from(AppConstants.tableTryonRatings)
        .delete()
        .eq(_tryonGenerationId, tryonId);
  }
}
