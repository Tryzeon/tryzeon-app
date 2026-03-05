import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/store/analytics/data/collections/product_analytics_collection.dart';
import 'package:tryzeon/feature/store/analytics/data/models/product_analytics_summary_model.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';

class ProductAnalyticsLocalDataSource {
  ProductAnalyticsLocalDataSource(this._isarService);

  final IsarService _isarService;
  static const _mappr = StoreMappr();

  Future<List<ProductAnalyticsSummaryModel>?> getProductAnalyticsSummaries(
    final String storeId,
    final int year,
    final int month,
  ) async {
    final isar = await _isarService.db;
    final collections = await isar.productAnalyticsCollections
        .filter()
        .storeIdEqualTo(storeId)
        .yearEqualTo(year)
        .monthEqualTo(month)
        .findAll();

    if (collections.isEmpty) return null;

    return collections
        .map(
          (final c) =>
              _mappr.convert<ProductAnalyticsCollection, ProductAnalyticsSummaryModel>(c),
        )
        .toList();
  }

  Future<void> saveProductAnalyticsSummaries(
    final List<ProductAnalyticsSummaryModel> summaries,
  ) async {
    final isar = await _isarService.db;

    await isar.writeTxn(() async {
      for (final summary in summaries) {
        final collection = _mappr
            .convert<ProductAnalyticsSummaryModel, ProductAnalyticsCollection>(summary);

        final existing = await isar.productAnalyticsCollections
            .filter()
            .storeIdEqualTo(summary.storeId)
            .productIdEqualTo(summary.productId)
            .yearEqualTo(summary.year)
            .monthEqualTo(summary.month)
            .findFirst();

        if (existing != null) {
          collection.id = existing.id;
        }

        await isar.productAnalyticsCollections.put(collection);
      }
    });
  }
}
