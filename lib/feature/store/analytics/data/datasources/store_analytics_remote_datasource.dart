import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/store/analytics/data/models/store_analytics_summary_model.dart';

class StoreAnalyticsRemoteDataSource {
  StoreAnalyticsRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  /// Fetches analytics for a specific month (single row by primary key).
  Future<StoreAnalyticsSummaryModel> getStoreAnalyticsSummary(
    final String storeId, {
    required final int year,
    required final int month,
  }) async {
    final response = await _supabaseClient
        .from(AppConstants.tableAnalyticsMonthlySummary)
        .select()
        .eq('store_id', storeId)
        .eq('year', year)
        .eq('month', month)
        .maybeSingle();

    if (response == null) {
      return StoreAnalyticsSummaryModel(
        storeId: storeId,
        year: year,
        month: month,
        viewCount: 0,
        tryonCount: 0,
        purchaseClickCount: 0,
      );
    }

    return StoreAnalyticsSummaryModel.fromJson(Map<String, dynamic>.from(response));
  }

  /// Fetches all monthly summaries for a store (for All time aggregation).
  Future<List<StoreAnalyticsSummaryModel>> getAllStoreAnalyticsSummaries(
    final String storeId,
  ) async {
    final response = await _supabaseClient
        .from(AppConstants.tableAnalyticsMonthlySummary)
        .select()
        .eq('store_id', storeId);

    return response
        .map(
          (final e) => StoreAnalyticsSummaryModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }
}
