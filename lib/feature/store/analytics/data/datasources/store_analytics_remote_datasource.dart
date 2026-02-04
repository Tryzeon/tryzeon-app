import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/store/analytics/data/models/store_analytics_summary_model.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';

class StoreAnalyticsRemoteDataSource {
  StoreAnalyticsRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<StoreAnalyticsSummary> getStoreAnalyticsSummary(
    final String storeId, {
    final int? year,
    final int? month,
  }) async {
    final response = await _supabaseClient.rpc(
      AppConstants.functionGetStoreAnalyticsSummary,
      params: {'p_store_id': storeId, 'p_year': year, 'p_month': month},
    );

    return StoreAnalyticsSummaryModel.fromJson(Map<String, dynamic>.from(response));
  }
}
