import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_storage.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';
import 'package:typed_result/typed_result.dart';
import 'package:uuid/uuid.dart';

part 'create_product.freezed.dart';

@freezed
sealed class CreateProductParams with _$CreateProductParams {
  const factory CreateProductParams({
    required final String storeId,
    required final ProductDraft draft,
    required final List<File> images,
    required final List<NewSizeItem> sizes,
  }) = _CreateProductParams;
}

class CreateProduct {
  CreateProduct({
    required final ProductRepository repository,
    required final ProductImageStorage imageStorage,
  }) : _repository = repository,
       _imageStorage = imageStorage;

  final ProductRepository _repository;
  final ProductImageStorage _imageStorage;
  static const _uuid = Uuid();

  Future<Result<void, Failure>> call(final CreateProductParams params) async {
    final productId = _uuid.v4();

    final uploaded = await _imageStorage.upload(
      storeId: params.storeId,
      productId: productId,
      images: params.images,
    );
    if (uploaded.isFailure) return Err(uploaded.getError()!);
    final imagePaths = uploaded.get()!;

    final created = await _repository.createProduct(
      NewProduct(
        id: productId,
        storeId: params.storeId,
        draft: params.draft,
        imagePaths: imagePaths,
        sizes: params.sizes,
      ),
    );
    if (created.isSuccess) return const Ok(null);

    final failure = created.getError()!;
    final rolledBack = await _repository.deleteProduct(
      storeId: params.storeId,
      productId: productId,
    );
    if (rolledBack.isFailure) {
      AppLogger.warning('Rollback of product $productId failed, keeping its images');
      return Err(failure);
    }

    if (imagePaths.isNotEmpty) {
      final deleted = await _imageStorage.delete(
        storeId: params.storeId,
        paths: imagePaths,
      );
      if (deleted.isFailure) {
        AppLogger.warning('Failed to delete images of rolled-back product $productId');
      }
    }
    return Err(failure);
  }
}
