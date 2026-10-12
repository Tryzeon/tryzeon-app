import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_local_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_remote_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/repositories/store_profile_repository_impl.dart';
import 'package:tryzeon/feature/store/profile/data/services/store_logo_storage_impl.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:tryzeon/feature/store/profile/domain/services/store_logo_storage.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/get_store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/usecases/update_store_profile.dart';
import 'package:tryzeon/feature/store/providers/store_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_profile_providers.g.dart';

@riverpod
StoreProfileRemoteDataSource storeProfileRemoteDataSource(final Ref ref) {
  return StoreProfileRemoteDataSource(ref.watch(supabaseClientProvider));
}

@riverpod
StoreLogoStorage storeLogoStorage(final Ref ref) {
  return StoreLogoStorageImpl(ref.watch(storeImagesApiProvider));
}

@riverpod
StoreProfileLocalDataSource storeProfileLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheEntryLocalDataSource = ref.watch(
    cacheEntryLocalDataSourceProvider,
  );
  return StoreProfileLocalDataSource(isarService, cacheEntryLocalDataSource);
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
  return UpdateStoreProfile(
    repository: ref.watch(storeProfileRepositoryProvider),
    logoStorage: ref.watch(storeLogoStorageProvider),
    geocoding: ref.watch(geocodingServiceProvider),
  );
}

@riverpod
class StoreProfileNotifier extends _$StoreProfileNotifier
    with PullToRefresh<StoreProfile?> {
  @override
  Future<StoreProfile?> build() async {
    final isLoggedIn = ref.watch(isAuthenticatedProvider);
    if (!isLoggedIn) return null;

    final getStoreProfile = ref.watch(getStoreProfileUseCaseProvider);
    final result = await getStoreProfile();
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get();
  }

  Future<Result<void, Failure>> refresh() => applyRefresh(
    () => ref.read(getStoreProfileUseCaseProvider)(forceRefresh: true),
  );
}

@riverpod
class StoreProfileEditNotifier extends _$StoreProfileEditNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// The profile the edits merge onto is read here rather than taken from the
  /// form, so a stale form can't clobber server-owned fields.
  Future<Result<({bool addressUnresolved}), Failure>> save({
    required final String name,
    required final String? address,
    required final Set<StoreChannel> channels,
    required final List<StoreOrderContact> orderContacts,
    final File? logoFile,
  }) async {
    // Kept alive for the duration, so a form popped mid-save doesn't dispose
    // this notifier out from under the pending `state` write.
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      final original = await ref.read(storeProfileProvider.future);
      if (original == null) {
        state = const AsyncData(null);
        return const Err(AuthFailure('無法獲取店家資訊，請重新登入'));
      }

      final result = await ref.read(updateStoreProfileUseCaseProvider)(
        UpdateStoreProfileParams(
          original: original,
          draft: StoreProfileDraft(
            name: name,
            address: address,
            channels: channels,
            orderContacts: orderContacts,
          ),
          logoFile: logoFile,
        ),
      );

      if (result.isFailure) {
        state = AsyncError(result.getError()!, StackTrace.current);
        return result;
      }

      ref.invalidate(storeProfileProvider);
      state = const AsyncData(null);
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save store profile', e, stackTrace);
      state = AsyncError(e, stackTrace);
      return Err(mapExceptionToFailure(e));
    } finally {
      link.close();
    }
  }
}
