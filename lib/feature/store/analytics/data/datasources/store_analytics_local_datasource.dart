import 'package:isar_community/isar.dart';
import 'package:tryzeon/app_mappr.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/store/analytics/data/collections/store_analytics_collection.dart';
import 'package:tryzeon/feature/store/analytics/data/models/store_analytics_summary_model.dart';

class StoreAnalyticsLocalDataSource {
  StoreAnalyticsLocalDataSource(this._isarService);

  final IsarService _isarService;
  static const _mappr = AppMappr();

  Future<StoreAnalyticsSummaryModel?> getStoreAnalyticsSummary(
    final String storeId,
    final int year,
    final int month,
  ) async {
    final isar = await _isarService.db;
    final collection = await isar.storeAnalyticsCollections
        .filter()
        .storeIdEqualTo(storeId)
        .yearEqualTo(year)
        .monthEqualTo(month)
        .findFirst();

    if (collection == null) return null;
    final model = _mappr.convert<StoreAnalyticsCollection, StoreAnalyticsSummaryModel>(
      collection,
    );
    return model;
  }

  Future<void> saveStoreAnalyticsSummary(
    final StoreAnalyticsSummaryModel summary, {
    required final String storeId,
    required final int year,
    required final int month,
  }) async {
    final isar = await _isarService.db;
    // Use manual toCollection with extra parameters (preserved method)
    final collection = summary.toCollection(storeId, year, month);

    await isar.writeTxn(() async {
      // Find existing to preserve ID if we want upsert, or just simple delete+insert or update
      // Since it's a composite unique key conceptually (storeId, year, month), we should check existence
      final existing = await isar.storeAnalyticsCollections
          .filter()
          .storeIdEqualTo(storeId)
          .yearEqualTo(year)
          .monthEqualTo(month)
          .findFirst();

      if (existing != null) {
        collection.id = existing.id;
      }

      await isar.storeAnalyticsCollections.put(collection);
    });
  }
}
