import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/repositories/product_analytics_repository_impl.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:tryzeon/feature/store/analytics/domain/usecases/get_product_analytics_summaries.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_analytics_providers.g.dart';

// --- Filter Provider (shared by dashboard + product cards) ---
@riverpod
class StoreAnalyticsFilter extends _$StoreAnalyticsFilter {
  @override
  ({int year, int month})? build() {
    final now = DateTime.now();
    return (year: now.year, month: now.month);
  }

  ({int year, int month})? get filter => state;

  set filter(final ({int year, int month})? filter) {
    state = filter;
  }
}

// --- Data Sources ---
@riverpod
ProductAnalyticsRemoteDataSource productAnalyticsRemoteDataSource(final Ref ref) {
  return ProductAnalyticsRemoteDataSource(Supabase.instance.client);
}

@riverpod
ProductAnalyticsLocalDataSource productAnalyticsLocalDataSource(final Ref ref) {
  return ProductAnalyticsLocalDataSource(IsarService());
}

// --- Repository ---
@riverpod
ProductAnalyticsRepository productAnalyticsRepository(final Ref ref) {
  return ProductAnalyticsRepositoryImpl(
    remoteDataSource: ref.watch(productAnalyticsRemoteDataSourceProvider),
    localDataSource: ref.watch(productAnalyticsLocalDataSourceProvider),
  );
}

// --- Use Case ---
@riverpod
GetProductAnalyticsSummaries getProductAnalyticsSummaries(final Ref ref) {
  return GetProductAnalyticsSummaries(
    ref.watch(productAnalyticsRepositoryProvider),
    ref.watch(storeProfileRepositoryProvider),
  );
}

// --- Feature Provider: per-product summaries ---
@riverpod
Future<List<ProductAnalyticsSummary>> productAnalyticsSummaries(final Ref ref) async {
  final filter = ref.watch(storeAnalyticsFilterProvider);
  final useCase = ref.watch(getProductAnalyticsSummariesProvider);
  final result = await useCase(year: filter?.year, month: filter?.month);

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}

/// Convenience provider: `Map<productId, summary>` for O(1) lookup
@riverpod
Map<String, ProductAnalyticsSummary> productAnalyticsMap(final Ref ref) {
  final summariesAsync = ref.watch(productAnalyticsSummariesProvider);
  return summariesAsync.maybeWhen(
    data: (final summaries) => {for (final s in summaries) s.productId: s},
    orElse: () => {},
  );
}

/// Force refresh analytics data
Future<void> refreshAnalytics(final WidgetRef ref) async {
  try {
    final _ = await ref.refresh(productAnalyticsSummariesProvider.future);
  } catch (_) {
    // Let UI show ErrorView or stale data
  }
}
