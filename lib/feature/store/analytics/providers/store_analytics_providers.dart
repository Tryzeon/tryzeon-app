import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/store_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/store_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/repositories/store_analytics_repository_impl.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/store_analytics_repository.dart';
import 'package:tryzeon/feature/store/analytics/domain/usecases/get_store_analytics_summary.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_analytics_providers.g.dart';

// --- Data Sources ---
@riverpod
StoreAnalyticsRemoteDataSource storeAnalyticsRemoteDataSource(final Ref ref) {
  return StoreAnalyticsRemoteDataSource(Supabase.instance.client);
}

@riverpod
StoreAnalyticsLocalDataSource storeAnalyticsLocalDataSource(final Ref ref) {
  return StoreAnalyticsLocalDataSource(IsarService());
}

// --- Filter Provider ---
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

// --- Repository ---
@riverpod
StoreAnalyticsRepository storeAnalyticsRepository(final Ref ref) {
  return StoreAnalyticsRepositoryImpl(
    ref.watch(storeAnalyticsRemoteDataSourceProvider),
    ref.watch(storeAnalyticsLocalDataSourceProvider),
  );
}

// --- Use Cases ---
@riverpod
GetStoreAnalyticsSummary getStoreAnalyticsSummary(final Ref ref) {
  return GetStoreAnalyticsSummary(
    ref.watch(storeAnalyticsRepositoryProvider),
    ref.watch(storeProfileRepositoryProvider),
  );
}

// --- Feature Providers ---
@riverpod
Future<StoreAnalyticsSummary> storeAnalyticsSummary(final Ref ref) async {
  final filter = ref.watch(storeAnalyticsFilterProvider);

  final useCase = ref.watch(getStoreAnalyticsSummaryProvider);
  final result = await useCase(year: filter?.year, month: filter?.month);

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}

/// 強制刷新分析數據
Future<void> refreshAnalytics(final WidgetRef ref) async {
  try {
    final _ = await ref.refresh(storeAnalyticsSummaryProvider.future);
  } catch (_) {
    // Provider 刷新失敗時，忽略異常，讓 UI 顯示 ErrorView 或舊資料
  }
}
