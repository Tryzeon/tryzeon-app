import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failure_from_error.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:tryzeon/feature/personal/profile/data/services/avatar_storage_impl.dart';
import 'package:tryzeon/feature/personal/profile/data/services/preset_avatar_source_impl.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/avatar_storage.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/preset_avatar_source.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/get_user_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/get_user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/prefetch_preset_avatars.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/select_preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_style_preferences.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_body_measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/upload_user_avatar.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'personal_profile_providers.freezed.dart';
part 'personal_profile_providers.g.dart';

@riverpod
UserProfileRemoteDataSource userProfileRemoteDataSource(final Ref ref) {
  return UserProfileRemoteDataSource(ref.watch(supabaseClientProvider));
}

@riverpod
UserProfileLocalDataSource userProfileLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final imageFileCache = ref.watch(imageFileCacheProvider);
  final cacheEntryLocalDataSource = ref.watch(
    cacheEntryLocalDataSourceProvider,
  );
  return UserProfileLocalDataSource(
    isarService,
    imageFileCache,
    cacheEntryLocalDataSource,
  );
}

@riverpod
UserProfileRepository userProfileRepository(final Ref ref) {
  return UserProfileRepositoryImpl(
    remoteDataSource: ref.watch(userProfileRemoteDataSourceProvider),
    localDataSource: ref.watch(userProfileLocalDataSourceProvider),
  );
}

@riverpod
GetUserProfile getUserProfileUseCase(final Ref ref) {
  return GetUserProfile(ref.watch(userProfileRepositoryProvider));
}

@riverpod
AvatarStorage avatarStorage(final Ref ref) {
  return AvatarStorageImpl(
    ref.watch(userProfileRemoteDataSourceProvider),
    ref.watch(userProfileLocalDataSourceProvider),
  );
}

@riverpod
UploadUserAvatar uploadUserAvatarUseCase(final Ref ref) {
  return UploadUserAvatar(
    repository: ref.watch(userProfileRepositoryProvider),
    avatarStorage: ref.watch(avatarStorageProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
}

@riverpod
PresetAvatarSource presetAvatarSource(final Ref ref) {
  return PresetAvatarSourceImpl(ref.watch(imageFileCacheProvider));
}

@riverpod
SelectPresetAvatar selectPresetAvatarUseCase(final Ref ref) {
  return SelectPresetAvatar(
    repository: ref.watch(userProfileRepositoryProvider),
    avatarStorage: ref.watch(avatarStorageProvider),
  );
}

@riverpod
GetUserAvatar getUserAvatarUseCase(final Ref ref) {
  return GetUserAvatar(
    repository: ref.watch(userProfileRepositoryProvider),
    presetAvatarSource: ref.watch(presetAvatarSourceProvider),
  );
}

@riverpod
PrefetchPresetAvatars prefetchPresetAvatarsUseCase(final Ref ref) {
  return PrefetchPresetAvatars(ref.watch(presetAvatarSourceProvider));
}

@riverpod
UpdateUserBodyMeasurements updateUserBodyMeasurementsUseCase(final Ref ref) {
  return UpdateUserBodyMeasurements(ref.watch(userProfileRepositoryProvider));
}

@riverpod
UpdateUserProfile updateUserProfileUseCase(final Ref ref) {
  return UpdateUserProfile(ref.watch(userProfileRepositoryProvider));
}

@riverpod
UpdateStylePreferences updateStylePreferencesUseCase(final Ref ref) {
  return UpdateStylePreferences(ref.watch(userProfileRepositoryProvider));
}

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier
    with PullToRefresh<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final isLoggedIn = ref.watch(isAuthenticatedProvider);
    if (!isLoggedIn) return null;

    final getUserProfileUseCase = ref.watch(getUserProfileUseCaseProvider);
    final result = await getUserProfileUseCase();
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  Future<Result<void, Failure>> refresh() => applyRefresh(
    () => ref.read(getUserProfileUseCaseProvider)(forceRefresh: true),
  );
}

@riverpod
Future<File?> avatarFile(final Ref ref) async {
  final avatar = (await ref.watch(userProfileProvider.future))?.avatar;
  if (avatar == null) return null;

  final result = await ref.watch(getUserAvatarUseCaseProvider)(avatar);

  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get();
}

@riverpod
Future<File> presetAvatarFile(final Ref ref, final PresetAvatar preset) async {
  final result = await ref.watch(getUserAvatarUseCaseProvider)(
    Avatar.preset(preset),
  );
  if (result.isFailure) throw result.getError()!;
  return result.get()!;
}

/// Warms the disk cache so the preset picker renders instantly; a failure only
/// logs, since the picker downloads on its own when it is shown.
@riverpod
Future<void> presetAvatarsPrefetch(final Ref ref, final Gender? gender) async {
  final result = await ref.watch(prefetchPresetAvatarsUseCaseProvider)(gender);
  if (result case Err(:final error)) {
    AppLogger.warning('Failed to prefetch preset avatars', error);
  }
}

@riverpod
class ProfileEditNotifier extends _$ProfileEditNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<void, Failure>> updateProfile(
    final UpdateUserProfileParams params,
  ) {
    return _write(() => ref.read(updateUserProfileUseCaseProvider)(params));
  }

  Future<Result<void, Failure>> updateBodyMeasurements(
    final BodyMeasurements measurements,
  ) {
    return _write(
      () => ref.read(updateUserBodyMeasurementsUseCaseProvider)(
        measurements: measurements,
      ),
    );
  }

  Future<Result<void, Failure>> updateStylePreferences(
    final List<ClothingStyle> stylePreferences,
  ) {
    return _write(
      () => ref.read(updateStylePreferencesUseCaseProvider)(
        stylePreferences: stylePreferences,
      ),
    );
  }

  /// Kept alive for the duration, so a form popped mid-write doesn't dispose
  /// this notifier out from under the pending `state` write.
  Future<Result<void, Failure>> _write(
    final Future<Result<void, Failure>> Function() write,
  ) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      final result = await write();
      if (result.isSuccess) {
        ref.invalidate(userProfileProvider);
      }
      state = result.isFailure
          ? AsyncError(result.getError()!, StackTrace.current)
          : const AsyncData(null);
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user profile', e, stackTrace);
      state = AsyncError(e, stackTrace);
      return Err(failureFromError(e));
    } finally {
      link.close();
    }
  }
}

/// What a replacement in flight is putting in place: the intent, not an image,
/// so the preview is resolved by the same providers that serve it elsewhere.
@freezed
sealed class PendingAvatar with _$PendingAvatar {
  const factory PendingAvatar.preset(final PresetAvatar preset) = PendingPreset;
  const factory PendingAvatar.photo(final File file) = PendingPhoto;
}

/// Null while nothing is being replaced, and while a preset's image is still
/// downloading or could not be fetched; the write proceeds either way, since
/// the backend reads a preset from R2 itself.
@riverpod
File? pendingAvatarPreview(final Ref ref) =>
    switch (ref.watch(avatarUploadProvider)) {
      PendingPhoto(:final file) => file,
      PendingPreset(:final preset) =>
        ref.watch(presetAvatarFileProvider(preset)).value,
      null => null,
    };

/// Non-null for as long as a replacement is in flight, so it is the one busy
/// signal.
@riverpod
class AvatarUploadNotifier extends _$AvatarUploadNotifier {
  @override
  PendingAvatar? build() => null;

  Future<Result<void, Failure>> applyPreset(final PresetAvatar preset) =>
      _replace(
        PendingAvatar.preset(preset),
        () => ref.read(selectPresetAvatarUseCaseProvider)(preset),
      );

  Future<Result<void, Failure>> upload(final File image) => _replace(
    PendingAvatar.photo(image),
    () => ref.read(uploadUserAvatarUseCaseProvider)(image),
  );

  /// Exclusive through the reload: interleaved replacements would each read
  /// the same previous avatar, orphaning one upload in storage.
  Future<Result<void, Failure>> _replace(
    final PendingAvatar pending,
    final Future<Result<void, Failure>> Function() write,
  ) async {
    if (state != null) return const Err(ValidationFailure());
    state = pending;
    final link = ref.keepAlive();
    try {
      final result = await write();

      if (result.isSuccess) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(avatarFileProvider);
        try {
          await ref.read(avatarFileProvider.future);
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Avatar saved but reloading it failed',
            e,
            stackTrace,
          );
        }
      }
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to replace avatar', e, stackTrace);
      return Err(failureFromError(e));
    } finally {
      state = null;
      link.close();
    }
  }
}
