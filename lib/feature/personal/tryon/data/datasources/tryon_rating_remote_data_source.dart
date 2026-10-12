import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_rating_request.dart';

class TryonRatingRemoteDataSource {
  TryonRatingRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  static const _tryonRatingsTable = 'tryon_ratings';
  static const _tryonGenerationId = 'tryon_generation_id';

  Future<void> upsert(final TryonRatingRequest request) async {
    await _supabase.from(_tryonRatingsTable).upsert(request.toJson());
  }

  Future<void> delete(final String tryonId) async {
    await _supabase
        .from(_tryonRatingsTable)
        .delete()
        .eq(_tryonGenerationId, tryonId);
  }
}
