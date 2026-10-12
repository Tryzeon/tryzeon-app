import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/repositories/product_analytics_repository_impl.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/analytics_month.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_traffic_totals.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:tryzeon/feature/store/analytics/domain/usecases/get_product_analytics_summaries.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_analytics_providers.g.dart';

@riverpod
class StoreAnalyticsFilter extends _$StoreAnalyticsFilter {
  @override
  AnalyticsMonth build() {
    final now = DateTime.now();
    return (year: now.year, month: now.month);
  }

  AnalyticsMonth get filter => state;

  set filter(final AnalyticsMonth filter) {
    state = filter;
  }
}

@riverpod
ProductAnalyticsRemoteDataSource productAnalyticsRemoteDataSource(
  final Ref ref,
) {
  return ProductAnalyticsRemoteDataSource(ref.watch(supabaseClientProvider));
}

@riverpod
ProductAnalyticsLocalDataSource productAnalyticsLocalDataSource(final Ref ref) {
  return ProductAnalyticsLocalDataSource(
    ref.watch(isarServiceProvider),
    ref.watch(cacheEntryLocalDataSourceProvider),
  );
}

@riverpod
ProductAnalyticsRepository productAnalyticsRepository(final Ref ref) {
  return ProductAnalyticsRepositoryImpl(
    remoteDataSource: ref.watch(productAnalyticsRemoteDataSourceProvider),
    localDataSource: ref.watch(productAnalyticsLocalDataSourceProvider),
  );
}

@riverpod
GetProductAnalyticsSummaries getProductAnalyticsSummaries(final Ref ref) {
  return GetProductAnalyticsSummaries(
    ref.watch(productAnalyticsRepositoryProvider),
  );
}

@riverpod
class ProductAnalyticsSummariesNotifier
    extends _$ProductAnalyticsSummariesNotifier
    with PullToRefresh<List<ProductAnalyticsSummary>> {
  @override
  Future<List<ProductAnalyticsSummary>> build() async {
    final result = await _fetch(
      profile: await ref.watch(storeProfileProvider.future),
      filter: ref.watch(storeAnalyticsFilterProvider),
      useCase: ref.watch(getProductAnalyticsSummariesProvider),
    );
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  Future<Result<void, Failure>> refresh() => applyRefresh(() async {
    final StoreProfile? profile;
    try {
      profile = await ref.read(storeProfileProvider.future);
    } on Failure catch (e) {
      return Err(e);
    }
    return _fetch(
      profile: profile,
      filter: ref.read(storeAnalyticsFilterProvider),
      useCase: ref.read(getProductAnalyticsSummariesProvider),
    );
  });

  Future<Result<List<ProductAnalyticsSummary>, Failure>> _fetch({
    required final StoreProfile? profile,
    required final AnalyticsMonth filter,
    required final GetProductAnalyticsSummaries useCase,
  }) async {
    if (profile == null) return const Ok([]);
    return useCase(
      GetProductAnalyticsSummariesParams(
        storeId: profile.id,
        year: filter.year,
        month: filter.month,
      ),
    );
  }
}

@riverpod
Future<StoreTrafficTotals> storeTrafficTotals(final Ref ref) async {
  final summaries = await ref.watch(productAnalyticsSummariesProvider.future);
  return StoreTrafficTotals.fromSummaries(summaries);
}
