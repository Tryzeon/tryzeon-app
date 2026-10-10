import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';

class TryonRatingRemoteDataSource {
  TryonRatingRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  static const _tryonGenerationId = 'tryon_generation_id';

  Future<void> upsert({
    required final String tryonId,
    required final String rating,
  }) async {
    await _supabase.from(AppConstants.tableTryonRatings).upsert({
      _tryonGenerationId: tryonId,
      'rating': rating,
    });
  }

  Future<void> delete(final String tryonId) async {
    await _supabase
        .from(AppConstants.tableTryonRatings)
        .delete()
        .eq(_tryonGenerationId, tryonId);
  }
}
