import 'dart:io';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/new_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/wardrobe_image_storage.dart';
import 'package:typed_result/typed_result.dart';
import 'package:uuid/uuid.dart';

part 'upload_wardrobe_item.freezed.dart';

@freezed
sealed class UploadWardrobeItemParams with _$UploadWardrobeItemParams {
  const factory UploadWardrobeItemParams({
    required final File image,
    required final GarmentType garmentType,
    @Default([]) final List<String> tags,
    final Uint8List? backgroundRemovedPng,
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

  Future<Result<WardrobeItem, Failure>> call(
    final UploadWardrobeItemParams params,
  ) async {
    final id = _uuid.v4();
    final uploaded = await _imageStorage.upload(
      itemId: id,
      image: params.image,
      backgroundRemovedPng: params.backgroundRemovedPng,
    );
    if (uploaded.isFailure) return Err(uploaded.getError()!);
    final imagePath = uploaded.get()!;

    final created = await _repository.createWardrobeItem(
      NewWardrobeItem(
        id: id,
        imagePath: imagePath,
        garmentType: params.garmentType,
        tags: params.tags,
      ),
    );
    if (created.isSuccess) return created;

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
