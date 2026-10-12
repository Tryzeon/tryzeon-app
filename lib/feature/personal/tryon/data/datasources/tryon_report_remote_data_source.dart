import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_report_request.dart';

class TryonReportRemoteDataSource {
  TryonReportRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;
  static const _contentReportsTable = 'content_reports';

  /// Never chain `.select()`: clients hold INSERT only on this table, and
  /// asking for the row back fails with 42501.
  Future<void> report(final TryonReportRequest request) async {
    await _supabase.from(_contentReportsTable).insert(request.toJson());
  }
}
