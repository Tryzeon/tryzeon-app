import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/store/analytics/data/dtos/product_analytics_summary_dto.dart';

class ProductAnalyticsRemoteDataSource {
  ProductAnalyticsRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _monthlySummaryTable = 'analytics_product_monthly_summary';

  Future<List<ProductAnalyticsSummaryDto>> getProductAnalyticsSummaries(
    final String storeId, {
    required final int year,
    required final int month,
  }) async {
    final response = await _supabaseClient
        .from(_monthlySummaryTable)
        .select()
        .eq('store_id', storeId)
        .eq('year', year)
        .eq('month', month);

    return response
        .map(
          (final e) =>
              ProductAnalyticsSummaryDto.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }
}
