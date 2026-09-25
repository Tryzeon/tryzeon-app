import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:tryzeon/feature/store/profile/domain/services/store_logo_storage.dart';
import 'package:typed_result/typed_result.dart';

part 'update_store_profile.freezed.dart';

@freezed
sealed class UpdateStoreProfileParams with _$UpdateStoreProfileParams {
  const factory UpdateStoreProfileParams({
    required final StoreProfile original,
    required final StoreProfileDraft draft,
    final File? logoFile,
  }) = _UpdateStoreProfileParams;
}

class UpdateStoreProfile {
  UpdateStoreProfile({
    required final StoreProfileRepository repository,
    required final StoreLogoStorage logoStorage,
  }) : _repository = repository,
       _logoStorage = logoStorage;

  final StoreProfileRepository _repository;
  final StoreLogoStorage _logoStorage;

  Future<Result<void, Failure>> call(final UpdateStoreProfileParams params) async {
    final original = params.original;
    var target = original.applyDraft(params.draft);

    String? uploadedLogoPath;
    final logoFile = params.logoFile;
    if (logoFile != null) {
      final uploaded = await _logoStorage.upload(storeId: original.id, logo: logoFile);
      if (uploaded.isFailure) return Err(uploaded.getError()!);
      uploadedLogoPath = uploaded.get()!;
      target = target.copyWith(logoPath: uploadedLogoPath);
    }

    final saved = await _repository.updateStoreProfile(
      original: original,
      target: target,
    );
    if (saved.isFailure) {
      final failure = saved.getError()!;
      if (uploadedLogoPath != null) {
        await _deleteLogo(original.id, uploadedLogoPath);
      }
      return Err(failure);
    }

    final oldLogoPath = original.logoPath;
    if (uploadedLogoPath != null &&
        oldLogoPath != null &&
        oldLogoPath.isNotEmpty &&
        oldLogoPath != uploadedLogoPath) {
      await _deleteLogo(original.id, oldLogoPath);
    }
    return const Ok(null);
  }

  Future<void> _deleteLogo(final String storeId, final String path) async {
    final deleted = await _logoStorage.delete(storeId: storeId, path: path);
    if (deleted.isFailure) {
      AppLogger.warning('Failed to delete store logo $path', deleted.getError());
    }
  }
}
