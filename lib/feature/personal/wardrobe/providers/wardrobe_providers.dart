import 'dart:io';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failure_from_error.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/apply_write.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_local_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_remote_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/background_remover_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/label_tagger_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/wardrobe_image_storage_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/label_result.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_capacity.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/background_remover.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/label_tagger.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/wardrobe_image_storage.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/delete_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/get_wardrobe_item_image.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/get_wardrobe_items.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/remove_wardrobe_image_background.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/tag_wardrobe_image.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/update_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/upload_wardrobe_item.dart';
import 'package:typed_result/typed_result.dart';

part 'wardrobe_providers.g.dart';

@riverpod
WardrobeRemoteDataSource wardrobeRemoteDataSource(final Ref ref) {
  return WardrobeRemoteDataSource(ref.watch(supabaseClientProvider));
}

@riverpod
WardrobeLocalDataSource wardrobeLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final imageFileCache = ref.watch(imageFileCacheProvider);
  final cacheEntryLocalDataSource = ref.watch(
    cacheEntryLocalDataSourceProvider,
  );
  return WardrobeLocalDataSource(
    isarService,
    imageFileCache,
    cacheEntryLocalDataSource,
  );
}

@riverpod
WardrobeRepository wardrobeRepository(final Ref ref) {
  return WardrobeRepositoryImpl(
    remoteDataSource: ref.watch(wardrobeRemoteDataSourceProvider),
    localDataSource: ref.watch(wardrobeLocalDataSourceProvider),
  );
}

@riverpod
GetWardrobeItems getWardrobeItemsUseCase(final Ref ref) {
  return GetWardrobeItems(ref.watch(wardrobeRepositoryProvider));
}

@riverpod
WardrobeImageStorage wardrobeImageStorage(final Ref ref) {
  return WardrobeImageStorageImpl(
    ref.watch(wardrobeRemoteDataSourceProvider),
    ref.watch(wardrobeLocalDataSourceProvider),
  );
}

@riverpod
UploadWardrobeItem uploadWardrobeItemUseCase(final Ref ref) {
  return UploadWardrobeItem(
    repository: ref.watch(wardrobeRepositoryProvider),
    imageStorage: ref.watch(wardrobeImageStorageProvider),
  );
}

@riverpod
DeleteWardrobeItem deleteWardrobeItemUseCase(final Ref ref) {
  return DeleteWardrobeItem(
    repository: ref.watch(wardrobeRepositoryProvider),
    imageStorage: ref.watch(wardrobeImageStorageProvider),
  );
}

@riverpod
UpdateWardrobeItem updateWardrobeItemUseCase(final Ref ref) {
  return UpdateWardrobeItem(ref.watch(wardrobeRepositoryProvider));
}

@riverpod
GetWardrobeItemImage getWardrobeItemImageUseCase(final Ref ref) {
  return GetWardrobeItemImage(ref.watch(wardrobeRepositoryProvider));
}

@riverpod
LabelTagger labelTagger(final Ref ref) =>
    LabelTaggerImpl(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
BackgroundRemover backgroundRemover(final Ref ref) => BackgroundRemoverImpl();

@riverpod
TagWardrobeImage tagWardrobeImageUseCase(final Ref ref) {
  return TagWardrobeImage(ref.watch(labelTaggerProvider));
}

@riverpod
RemoveWardrobeImageBackground removeWardrobeImageBackgroundUseCase(
  final Ref ref,
) {
  return RemoveWardrobeImageBackground(ref.watch(backgroundRemoverProvider));
}

@riverpod
Future<LabelResult> wardrobeImageLabels(
  final Ref ref,
  final String imagePath,
) async {
  final result = await ref.watch(tagWardrobeImageUseCaseProvider)(
    File(imagePath),
  );
  if (result.isFailure) throw result.getError()!;
  return result.get()!;
}

@riverpod
Future<Uint8List?> wardrobeImageWithoutBackground(
  final Ref ref,
  final String imagePath,
) async {
  final result = await ref.watch(removeWardrobeImageBackgroundUseCaseProvider)(
    File(imagePath),
  );
  if (result.isFailure) throw result.getError()!;
  return result.get();
}

/// Keyed on the signed-in user, not on who is listening: a keepAlive holder
/// (the outfit tray) must never carry one account's list into the next.
@riverpod
class WardrobeItemsNotifier extends _$WardrobeItemsNotifier
    with PullToRefresh<List<WardrobeItem>>, ApplyWrite<List<WardrobeItem>> {
  @override
  Future<List<WardrobeItem>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];

    final getWardrobeItemsUseCase = ref.watch(getWardrobeItemsUseCaseProvider);
    final result = await getWardrobeItemsUseCase();
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  Future<Result<void, Failure>> refresh() => applyRefresh(
    () => ref.read(getWardrobeItemsUseCaseProvider)(forceRefresh: true),
  );

  Future<Result<WardrobeItem, Failure>> uploadItem(
    final UploadWardrobeItemParams params,
  ) => applyWrite(
    () => ref.read(uploadWardrobeItemUseCaseProvider)(params),
    merge: (final items, final created) => [created, ...items],
  );

  Future<Result<WardrobeItem, Failure>> updateItem(
    final UpdateWardrobeItemParams params,
  ) => applyWrite(
    () => ref.read(updateWardrobeItemUseCaseProvider)(params),
    merge: (final items, final updated) => [
      for (final item in items) item.id == updated.id ? updated : item,
    ],
  );

  Future<Result<void, Failure>> deleteItem(final WardrobeItem target) =>
      applyWrite(
        () => ref.read(deleteWardrobeItemUseCaseProvider)(target),
        merge: (final items, final _) => [
          for (final item in items)
            if (item.id != target.id) item,
        ],
      );
}

@riverpod
Future<WardrobeCapacity> wardrobeCapacity(final Ref ref) async {
  final capabilities = await ref.watch(subscriptionCapabilitiesProvider.future);
  final items = await ref.watch(wardrobeItemsProvider.future);
  return WardrobeCapacity(
    used: items.length,
    limit: capabilities.wardrobeLimit,
  );
}

/// Exposes progress via [state] so a sheet can drive its save button without a
/// hand-rolled flag, and also returns the [Result] so the caller can surface a
/// one-shot failure.
@riverpod
class WardrobeEditNotifier extends _$WardrobeEditNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<void, Failure>> upload(final UploadWardrobeItemParams params) {
    return _write(
      () => ref.read(wardrobeItemsProvider.notifier).uploadItem(params),
    );
  }

  Future<Result<void, Failure>> update(final UpdateWardrobeItemParams params) {
    return _write(
      () => ref.read(wardrobeItemsProvider.notifier).updateItem(params),
    );
  }

  Future<Result<void, Failure>> delete(final WardrobeItem item) {
    return _write(
      () => ref.read(wardrobeItemsProvider.notifier).deleteItem(item),
    );
  }

  /// Kept alive for the duration, so a sheet popped mid-write doesn't dispose
  /// this notifier out from under the pending `state` write.
  Future<Result<void, Failure>> _write(
    final Future<Result<Object?, Failure>> Function() write,
  ) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      final result = (await write()).map((final _) {});
      state = result.isFailure
          ? AsyncError(result.getError()!, StackTrace.current)
          : const AsyncData(null);
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Wardrobe write failed', e, stackTrace);
      state = AsyncError(e, stackTrace);
      return Err(failureFromError(e));
    } finally {
      link.close();
    }
  }
}

@riverpod
Future<File> wardrobeItemImage(final Ref ref, final String imagePath) async {
  final getWardrobeItemImageUseCase = ref.watch(
    getWardrobeItemImageUseCaseProvider,
  );
  final result = await getWardrobeItemImageUseCase(imagePath);
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}
