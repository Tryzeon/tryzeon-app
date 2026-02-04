import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/store_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/repositories/store_analytics_repository_impl.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/store_analytics_repository.dart';
import 'package:tryzeon/feature/store/analytics/domain/usecases/get_store_analytics_summary.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

// --- Data Sources ---

final storeAnalyticsRemoteDataSourceProvider = Provider<StoreAnalyticsRemoteDataSource>((
  final ref,
) {
  return StoreAnalyticsRemoteDataSource(Supabase.instance.client);
});

// --- Repository ---

final storeAnalyticsRepositoryProvider = Provider<StoreAnalyticsRepository>((final ref) {
  return StoreAnalyticsRepositoryImpl(ref.watch(storeAnalyticsRemoteDataSourceProvider));
});

// --- Use Cases ---

final getStoreAnalyticsSummaryProvider = Provider<GetStoreAnalyticsSummary>((final ref) {
  return GetStoreAnalyticsSummary(
    ref.watch(storeAnalyticsRepositoryProvider),
    ref.watch(storeProfileRepositoryProvider),
  );
});

// --- Feature Providers ---

final storeAnalyticsSummaryProvider = FutureProvider<StoreAnalyticsSummary>((
  final ref,
) async {
  final useCase = ref.watch(getStoreAnalyticsSummaryProvider);

  // Calls usecase without arguments to fetch "All Time" total.
  // The UseCase internally fetches the current store profile.
  final result = await useCase();

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
});

/// 強制刷新分析數據
Future<void> refreshAnalytics(final WidgetRef ref) async {
  try {
    final _ = await ref.refresh(storeAnalyticsSummaryProvider.future);
  } catch (_) {
    // Provider 刷新失敗時，忽略異常，讓 UI 顯示 ErrorView 或舊資料
  }
}
