import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/datasources/analytics_remote_datasource.dart';
import 'package:tryzeon/core/data/services/cache_service_impl.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/data/services/location_service_impl.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/core/domain/services/location_service.dart';
import 'package:tryzeon/core/services/analytics_event_queue_service.dart';

part 'core_providers.g.dart';

/// Analytics Remote DataSource Provider
@riverpod
AnalyticsRemoteDataSource analyticsRemoteDataSource(final Ref ref) {
  return AnalyticsRemoteDataSource(Supabase.instance.client);
}

/// Analytics Event Queue Service Provider
@riverpod
AnalyticsEventQueueService analyticsEventQueueService(final Ref ref) {
  final analyticsDataSource = ref.watch(analyticsRemoteDataSourceProvider);

  return AnalyticsEventQueueService(
    uploadCallback: analyticsDataSource.uploadAnalyticsEvents,
  );
}

/// Location Service Provider
@riverpod
LocationService locationService(final Ref ref) {
  return LocationServiceImpl();
}

/// Cache Service Provider
@riverpod
CacheService cacheService(final Ref ref) {
  return CacheServiceImpl();
}

/// Isar Database Service Provider
@riverpod
IsarService isarService(final Ref ref) {
  return IsarService();
}
