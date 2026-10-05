import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/image_file_cache_impl.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/data/services/local_database_impl.dart';
import 'package:tryzeon/core/domain/services/image_file_cache.dart';
import 'package:tryzeon/core/domain/services/local_database.dart';
import 'package:tryzeon/core/modules/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:tryzeon/core/modules/analytics/data/dtos/analytics_event_dto.dart';
import 'package:tryzeon/core/modules/analytics/data/mappers/analytics_mappr.dart';
import 'package:tryzeon/core/modules/analytics/data/services/analytics_event_queue_impl.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/core/modules/auth_identity/data/services/auth_identity_service_impl.dart';
import 'package:tryzeon/core/modules/auth_identity/domain/services/auth_identity_service.dart';
import 'package:tryzeon/core/modules/location/data/services/geocoding_service_impl.dart';
import 'package:tryzeon/core/modules/location/data/services/location_service_impl.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';
import 'package:tryzeon/core/modules/location/domain/services/location_service.dart';

part 'core_providers.g.dart';

const _mappr = AnalyticsMappr();

@riverpod
AnalyticsRemoteDataSource analyticsRemoteDataSource(final Ref ref) {
  return AnalyticsRemoteDataSource(Supabase.instance.client);
}

@Riverpod(keepAlive: true)
AnalyticsEventQueue analyticsEventQueue(final Ref ref) {
  final analyticsDataSource = ref.watch(analyticsRemoteDataSourceProvider);

  return AnalyticsEventQueueImpl(
    uploadCallback: (final events) {
      final models = _mappr.convertList<AnalyticsEvent, AnalyticsEventDto>(
        events,
      );
      return analyticsDataSource.uploadAnalyticsEvents(models);
    },
  );
}

@riverpod
LocationService locationService(final Ref ref) {
  return LocationServiceImpl();
}

@riverpod
GeocodingService geocodingService(final Ref ref) {
  return GeocodingServiceImpl();
}

@Riverpod(keepAlive: true)
ImageFileCache imageFileCache(final Ref ref) {
  return ImageFileCacheImpl();
}

@Riverpod(keepAlive: true)
IsarService isarService(final Ref ref) {
  return IsarService();
}

@Riverpod(keepAlive: true)
LocalDatabase localDatabase(final Ref ref) {
  return LocalDatabaseImpl(ref.watch(isarServiceProvider));
}

@Riverpod(keepAlive: true)
CacheEntryLocalDataSource cacheEntryLocalDataSource(final Ref ref) {
  return CacheEntryLocalDataSource(ref.watch(isarServiceProvider));
}

@Riverpod(keepAlive: true)
AuthIdentityService authIdentityService(final Ref ref) {
  return AuthIdentityServiceImpl(Supabase.instance.client.auth);
}
