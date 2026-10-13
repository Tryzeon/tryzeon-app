import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/image_file_cache.dart';
import 'package:tryzeon/core/data/services/image_file_cache_impl.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/data/services/local_data_store_impl.dart';
import 'package:tryzeon/core/domain/services/local_data_store.dart';
import 'package:tryzeon/core/modules/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:tryzeon/core/modules/analytics/data/services/analytics_event_queue_impl.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/core/modules/auth_identity/data/services/auth_identity_service_impl.dart';
import 'package:tryzeon/core/modules/auth_identity/domain/services/auth_identity_service.dart';
import 'package:tryzeon/core/modules/location/data/services/geocoding_service_impl.dart';
import 'package:tryzeon/core/modules/location/data/services/location_service_impl.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';
import 'package:tryzeon/core/modules/location/domain/services/location_service.dart';

part 'core_providers.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(final Ref ref) => Supabase.instance.client;

@Riverpod(keepAlive: true)
FirebaseAnalytics firebaseAnalytics(final Ref ref) =>
    FirebaseAnalytics.instance;

@riverpod
AnalyticsRemoteDataSource analyticsRemoteDataSource(final Ref ref) {
  return AnalyticsRemoteDataSource(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
AnalyticsEventQueue analyticsEventQueue(final Ref ref) {
  return AnalyticsEventQueueImpl(ref.watch(analyticsRemoteDataSourceProvider));
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
Dio dio(final Ref ref) {
  final dio = Dio();
  ref.onDispose(dio.close);
  return dio;
}

@Riverpod(keepAlive: true)
SharedPreferencesAsync sharedPreferences(final Ref ref) {
  return SharedPreferencesAsync();
}

@Riverpod(keepAlive: true)
BaseCacheManager cacheManager(final Ref ref) {
  return DefaultCacheManager();
}

@Riverpod(keepAlive: true)
ImageFileCache imageFileCache(final Ref ref) {
  return ImageFileCacheImpl(ref.watch(cacheManagerProvider));
}

@Riverpod(keepAlive: true)
IsarService isarService(final Ref ref) {
  return IsarService();
}

@Riverpod(keepAlive: true)
LocalDataStore localDataStore(final Ref ref) {
  return LocalDataStoreImpl(
    ref.watch(isarServiceProvider),
    ref.watch(imageFileCacheProvider),
  );
}

@Riverpod(keepAlive: true)
CacheEntryLocalDataSource cacheEntryLocalDataSource(final Ref ref) {
  return CacheEntryLocalDataSource(ref.watch(isarServiceProvider));
}

@Riverpod(keepAlive: true)
AuthIdentityService authIdentityService(final Ref ref) {
  return AuthIdentityServiceImpl(ref.watch(supabaseClientProvider).auth);
}
