import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/dtos/product_analytics_summary_dto.dart';
import 'package:tryzeon/feature/store/analytics/data/repositories/product_analytics_repository_impl.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRemote implements ProductAnalyticsRemoteDataSource {
  int calls = 0;

  @override
  Future<List<ProductAnalyticsSummaryDto>> getProductAnalyticsSummaries(
    final String storeId, {
    required final int year,
    required final int month,
  }) async {
    calls++;
    return [
      ProductAnalyticsSummaryDto(
        storeId: storeId,
        productId: 'p1',
        year: year,
        month: month,
        viewCount: 3,
        tryonCount: 2,
        purchaseClickCount: 1,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _BrokenLocal implements ProductAnalyticsLocalDataSource {
  @override
  Future<CacheLookup<List<ProductAnalyticsSummary>>>
  getProductAnalyticsSummaries(
    final String storeId,
    final int year,
    final int month,
  ) async => throw Exception('cache read failed');

  @override
  Future<void> saveProductAnalyticsSummaries(
    final String storeId,
    final int year,
    final int month,
    final List<ProductAnalyticsSummary> summaries,
  ) async => throw Exception('cache write failed');

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test(
    'serves a past month from remote when the cache cannot be read or written',
    () async {
      final remote = _FakeRemote();
      final repository = ProductAnalyticsRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: _BrokenLocal(),
      );

      final result = await repository.getProductAnalyticsSummaries(
        's1',
        year: 2025,
        month: 1,
      );

      expect(remote.calls, 1);
      expect(result.get()?.single.viewCount, 3);
    },
  );
}
