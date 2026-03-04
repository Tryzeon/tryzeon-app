import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_local_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_remote_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/repositories/store_profile_repository_impl.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/get_store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/update_store_profile.dart';
import 'package:typed_result/typed_result.dart';

part 'store_profile_providers.g.dart';

@riverpod
StoreProfileRemoteDataSource storeProfileRemoteDataSource(final Ref ref) {
  return StoreProfileRemoteDataSource(Supabase.instance.client);
}

@riverpod
StoreProfileLocalDataSource storeProfileLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return StoreProfileLocalDataSource(isarService, cacheService);
}

@riverpod
StoreProfileRepository storeProfileRepository(final Ref ref) {
  return StoreProfileRepositoryImpl(
    remoteDataSource: ref.watch(storeProfileRemoteDataSourceProvider),
    localDataSource: ref.watch(storeProfileLocalDataSourceProvider),
  );
}

@riverpod
GetStoreProfile getStoreProfileUseCase(final Ref ref) {
  return GetStoreProfile(ref.watch(storeProfileRepositoryProvider));
}

@riverpod
UpdateStoreProfile updateStoreProfileUseCase(final Ref ref) {
  return UpdateStoreProfile(ref.watch(storeProfileRepositoryProvider));
}

@riverpod
Future<StoreProfile?> storeProfile(final Ref ref) async {
  final isLoggedIn = ref.watch(isAuthenticatedProvider);
  if (!isLoggedIn) return null;

  final getStoreProfile = ref.watch(getStoreProfileUseCaseProvider);
  final result = await getStoreProfile();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get();
}
