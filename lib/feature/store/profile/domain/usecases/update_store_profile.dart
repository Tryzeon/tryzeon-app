import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/location/domain/services/geocoding_service.dart';
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
    required final GeocodingService geocoding,
  }) : _repository = repository,
       _logoStorage = logoStorage,
       _geocoding = geocoding;

  final StoreProfileRepository _repository;
  final StoreLogoStorage _logoStorage;
  final GeocodingService _geocoding;

  Future<Result<({bool addressUnresolved}), Failure>> call(
    final UpdateStoreProfileParams params,
  ) async {
    final original = params.original;
    final located = await _locate(original, params.draft.address);
    var target = original
        .applyDraft(params.draft)
        .copyWith(latitude: located.latitude, longitude: located.longitude);

    String? uploadedLogoPath;
    String? replacedLogoPath;
    final logoFile = params.logoFile;
    if (logoFile != null) {
      final current = await _repository.getStoreProfile(forceRefresh: true);
      if (current.isFailure) return Err(current.getError()!);
      replacedLogoPath = current.get()?.logoPath;

      final uploaded = await _logoStorage.upload(
        storeId: original.id,
        logo: logoFile,
      );
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

    if (uploadedLogoPath != null &&
        replacedLogoPath != null &&
        replacedLogoPath.isNotEmpty &&
        replacedLogoPath != uploadedLogoPath) {
      await _deleteLogo(original.id, replacedLogoPath);
    }
    return Ok((addressUnresolved: located.unresolved));
  }

  Future<({double? latitude, double? longitude, bool unresolved})> _locate(
    final StoreProfile original,
    final String? address,
  ) async {
    if (address == original.address) {
      return (
        latitude: original.latitude,
        longitude: original.longitude,
        unresolved: false,
      );
    }
    if (address == null || address.isEmpty) {
      return (latitude: null, longitude: null, unresolved: false);
    }

    final coordinates = (await _geocoding.geocodeAddress(address)).get();
    return (
      latitude: coordinates?.latitude,
      longitude: coordinates?.longitude,
      unresolved: coordinates == null,
    );
  }

  Future<void> _deleteLogo(final String storeId, final String path) async {
    final deleted = await _logoStorage.delete(storeId: storeId, path: path);
    if (deleted.isFailure) {
      AppLogger.warning(
        'Failed to delete store logo $path',
        deleted.getError(),
      );
    }
  }
}
