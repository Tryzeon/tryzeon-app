import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:typed_result/typed_result.dart';
import 'package:uuid/uuid.dart';

import '../entities/new_wardrobe_item.dart';
import '../repositories/wardrobe_repository.dart';
import '../services/wardrobe_image_storage.dart';

part 'upload_wardrobe_item.freezed.dart';

@freezed
sealed class UploadWardrobeItemParams with _$UploadWardrobeItemParams {
  const factory UploadWardrobeItemParams({
    required final File image,
    required final GarmentType garmentType,
    @Default([]) final List<String> tags,
  }) = _UploadWardrobeItemParams;
}

class UploadWardrobeItem {
  UploadWardrobeItem({
    required final WardrobeRepository repository,
    required final WardrobeImageStorage imageStorage,
  }) : _repository = repository,
       _imageStorage = imageStorage;

  final WardrobeRepository _repository;
  final WardrobeImageStorage _imageStorage;
  static const _uuid = Uuid();

  Future<Result<void, Failure>> call(
    final UploadWardrobeItemParams params,
  ) async {
    final uploaded = await _imageStorage.upload(
      image: params.image,
      garmentType: params.garmentType,
    );
    if (uploaded.isFailure) return Err(uploaded.getError()!);
    final imagePath = uploaded.get()!;

    final created = await _repository.createWardrobeItem(
      NewWardrobeItem(
        id: _uuid.v4(),
        imagePath: imagePath,
        garmentType: params.garmentType,
        tags: params.tags,
      ),
    );
    if (created.isSuccess) return const Ok(null);

    final deleted = await _imageStorage.delete(imagePath);
    if (deleted.isFailure) {
      AppLogger.warning(
        'Failed to delete wardrobe image $imagePath',
        deleted.getError(),
      );
    }
    return created;
  }
}
