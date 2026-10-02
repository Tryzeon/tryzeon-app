import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/image_analysis_api.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_local_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_remote_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/background_remover_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/label_tagger_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/wardrobe_image_storage_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_capacity.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/background_remover.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/label_tagger.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/wardrobe_image_storage.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/analyze_wardrobe_image.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/delete_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/get_wardrobe_item_image.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/get_wardrobe_items.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/update_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/upload_wardrobe_item.dart';
import 'package:typed_result/typed_result.dart';

part 'wardrobe_providers.g.dart';

@riverpod
WardrobeRemoteDataSource wardrobeRemoteDataSource(final Ref ref) {
  return WardrobeRemoteDataSource(Supabase.instance.client);
}

@riverpod
WardrobeLocalDataSource wardrobeLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final imageFileCache = ref.watch(imageFileCacheProvider);
  final cacheEntryLocalDataSource = ref.watch(cacheEntryLocalDataSourceProvider);
  return WardrobeLocalDataSource(isarService, imageFileCache, cacheEntryLocalDataSource);
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
    LabelTaggerImpl(ref.watch(imageAnalysisApiProvider));

@Riverpod(keepAlive: true)
BackgroundRemover backgroundRemover(final Ref ref) => BackgroundRemoverImpl();

@Riverpod(keepAlive: true)
AnalyzeWardrobeImage analyzeWardrobeImageUseCase(final Ref ref) {
  return AnalyzeWardrobeImage(
    labelTagger: ref.watch(labelTaggerProvider),
    backgroundRemover: ref.watch(backgroundRemoverProvider),
  );
}

/// Keyed on the signed-in user, not on who is listening: a keepAlive holder
/// (the outfit tray) must never carry one account's list into the next.
@riverpod
class WardrobeItemsNotifier extends _$WardrobeItemsNotifier
    with PullToRefresh<List<WardrobeItem>> {
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

  Future<Result<void, Failure>> refresh() =>
      applyRefresh(() => ref.read(getWardrobeItemsUseCaseProvider)(forceRefresh: true));
}

@riverpod
Future<WardrobeCapacity> wardrobeCapacity(final Ref ref) async {
  final capabilities = await ref.watch(subscriptionCapabilitiesProvider.future);
  final items = await ref.watch(wardrobeItemsProvider.future);
  return WardrobeCapacity(used: items.length, limit: capabilities.wardrobeLimit);
}

/// Exposes progress via [state] so a sheet can drive its save button without a
/// hand-rolled flag, and also returns the [Result] so the caller can surface a
/// one-shot failure.
@riverpod
class WardrobeEditNotifier extends _$WardrobeEditNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<void, Failure>> upload({
    required final File image,
    required final GarmentType garmentType,
    required final List<String> tags,
    final Uint8List? replacementBytes,
  }) {
    return _write(() async {
      final capacity = await ref.read(wardrobeCapacityProvider.future);

      final tempFile = replacementBytes == null
          ? null
          : await _writeTempPng(replacementBytes, basedOn: image);

      try {
        return await ref.read(uploadWardrobeItemUseCaseProvider)(
          params: CreateWardrobeItemParams(
            image: tempFile ?? image,
            garmentType: garmentType,
            tags: tags,
          ),
          capacity: capacity,
        );
      } finally {
        try {
          await tempFile?.delete();
        } catch (e, st) {
          AppLogger.warning('Failed to delete temp upload file', e, st);
        }
      }
    });
  }

  Future<Result<void, Failure>> update(final UpdateWardrobeItemParams params) {
    return _write(
      () async => ref
          .read(updateWardrobeItemUseCaseProvider)(params)
          .then((final result) => result.map((final _) {})),
    );
  }

  Future<Result<void, Failure>> delete(final WardrobeItem item) {
    return _write(() => ref.read(deleteWardrobeItemUseCaseProvider)(item));
  }

  Future<File> _writeTempPng(final Uint8List bytes, {required final File basedOn}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wardrobe_nobg_${basedOn.uri.pathSegments.last}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Kept alive for the duration, so a sheet popped mid-write doesn't dispose
  /// this notifier out from under the pending `state` write.
  Future<Result<void, Failure>> _write(
    final Future<Result<void, Failure>> Function() write,
  ) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      final result = await write();
      if (result.isSuccess) {
        ref.invalidate(wardrobeItemsProvider);
      }
      state = result.isFailure
          ? AsyncError(result.getError()!, StackTrace.current)
          : const AsyncData(null);
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Wardrobe write failed', e, stackTrace);
      state = AsyncError(e, stackTrace);
      return Err(mapExceptionToFailure(e));
    } finally {
      link.close();
    }
  }
}

@riverpod
Future<File> wardrobeItemImage(final Ref ref, final String imagePath) async {
  final getWardrobeItemImageUseCase = ref.watch(getWardrobeItemImageUseCaseProvider);
  final result = await getWardrobeItemImageUseCase(imagePath);
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}
