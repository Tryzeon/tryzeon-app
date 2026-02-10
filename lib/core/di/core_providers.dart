import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/cache_service_impl.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/core/modules/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:tryzeon/core/modules/analytics/data/mappers/analytics_event_mapper.dart';
import 'package:tryzeon/core/modules/analytics/data/services/analytics_event_queue_service.dart';
import 'package:tryzeon/core/modules/location/data/services/location_service_impl.dart';
import 'package:tryzeon/core/modules/location/domain/services/location_service.dart';

part 'core_providers.g.dart';

/// Analytics Remote DataSource Provider
@riverpod
AnalyticsRemoteDataSource analyticsRemoteDataSource(final Ref ref) {
  return AnalyticsRemoteDataSource(Supabase.instance.client);
}

/// Analytics Event Queue Service Provider
@Riverpod(keepAlive: true)
AnalyticsEventQueueService analyticsEventQueueService(final Ref ref) {
  final analyticsDataSource = ref.watch(analyticsRemoteDataSourceProvider);

  return AnalyticsEventQueueService(
    uploadCallback: (final events) {
      final models = events.map((final e) => e.toModel()).toList();
      return analyticsDataSource.uploadAnalyticsEvents(models);
    },
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
