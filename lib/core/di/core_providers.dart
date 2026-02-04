import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/datasources/analytics_remote_datasource.dart';
import 'package:tryzeon/core/data/services/cache_service_impl.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/data/services/location_service_impl.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/core/domain/services/location_service.dart';
import 'package:tryzeon/core/services/analytics_event_queue_service.dart';

/// Analytics Remote DataSource Provider
final analyticsRemoteDataSourceProvider = Provider<AnalyticsRemoteDataSource>((
  final ref,
) {
  return AnalyticsRemoteDataSource(Supabase.instance.client);
});

/// Analytics Event Queue Service Provider
final analyticsEventQueueServiceProvider = Provider<AnalyticsEventQueueService>((
  final ref,
) {
  final analyticsDataSource = ref.watch(analyticsRemoteDataSourceProvider);

  return AnalyticsEventQueueService(
    uploadCallback: analyticsDataSource.uploadAnalyticsEvents,
  );
});

/// Location Service Provider
final locationServiceProvider = Provider<LocationService>((final ref) {
  return LocationServiceImpl();
});

/// Cache Service Provider
final cacheServiceProvider = Provider<CacheService>((final ref) {
  return CacheServiceImpl();
});

/// Isar Database Service Provider
final isarServiceProvider = Provider<IsarService>((final ref) {
  return IsarService();
});
