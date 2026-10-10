import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';

class TryonReportRemoteDataSource {
  TryonReportRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;

  /// Never chain `.select()`: clients hold INSERT only on this table, and
  /// asking for the row back fails with 42501.
  Future<void> report(final String tryonId) async {
    await _supabase.from(AppConstants.tableContentReports).insert({
      'tryon_generation_id': tryonId,
    });
  }
}
