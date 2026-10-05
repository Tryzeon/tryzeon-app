import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_storage.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_update_plan.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';
import 'package:typed_result/typed_result.dart';

part 'update_product.freezed.dart';

@freezed
sealed class UpdateProductParams with _$UpdateProductParams {
  const factory UpdateProductParams({
    required final Product original,
    required final ProductDraft draft,
    required final List<ImageItem> images,
    required final List<SizeItem> sizes,
  }) = _UpdateProductParams;
}

class UpdateProduct {
  UpdateProduct({
    required final ProductRepository repository,
    required final ProductImageStorage imageStorage,
  }) : _repository = repository,
       _imageStorage = imageStorage;

  final ProductRepository _repository;
  final ProductImageStorage _imageStorage;

  Future<Result<void, Failure>> call(final UpdateProductParams params) async {
    final original = params.original;
    final newFiles = <File>[
      for (final item in params.images)
        if (item case NewImageItem(:final file)) file,
    ];

    var uploadedPaths = const <String>[];
    if (newFiles.isNotEmpty) {
      final uploaded = await _imageStorage.upload(
        storeId: original.storeId,
        productId: original.id,
        images: newFiles,
      );
      if (uploaded.isFailure) return Err(uploaded.getError()!);
      uploadedPaths = uploaded.get()!;
    }

    final plan = planProductUpdate(
      original: original,
      draft: params.draft,
      images: params.images,
      uploadedPaths: uploadedPaths,
      sizes: params.sizes,
    );
    if (plan.isEmpty) return const Ok(null);

    final saved = await _repository.updateProduct(
      original: original,
      plan: plan,
    );
    if (saved.isFailure) {
      final failure = saved.getError()!;
      if (uploadedPaths.isNotEmpty) {
        await _deleteImages(original.storeId, uploadedPaths);
      }
      return Err(failure);
    }

    if (plan.removedImagePaths.isNotEmpty) {
      await _deleteImages(original.storeId, plan.removedImagePaths);
    }
    return const Ok(null);
  }

  Future<void> _deleteImages(
    final String storeId,
    final List<String> paths,
  ) async {
    final deleted = await _imageStorage.delete(storeId: storeId, paths: paths);
    if (deleted.isFailure) {
      AppLogger.warning(
        'Failed to delete product images $paths',
        deleted.getError(),
      );
    }
  }
}
