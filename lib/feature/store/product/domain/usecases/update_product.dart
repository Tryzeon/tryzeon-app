import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/failures/invalid_product_colors_failure.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_rules.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_storage.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_update_plan.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';
import 'package:typed_result/typed_result.dart';

part 'update_product.freezed.dart';

@freezed
sealed class UpdateProductParams with _$UpdateProductParams {
  const factory UpdateProductParams({
    required final Product original,
    required final ProductDraft draft,
    required final List<ColorItem> colors,
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

  Future<Result<Product?, Failure>> call(
    final UpdateProductParams params,
  ) async {
    final original = params.original;
    if (!isValidColorSet(params.colors)) {
      return const Err(InvalidProductColorsFailure());
    }

    final newFiles = params.colors.newImageFiles;

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
      colors: params.colors,
      uploadedPaths: uploadedPaths,
      sizes: params.sizes,
    );
    if (plan.isEmpty) {
      if (plan.removedImagePaths.isNotEmpty) {
        await _deleteImages(original.storeId, plan.removedImagePaths);
      }
      return Ok(original);
    }

    final saved = await _repository.updateProduct(
      original: original,
      target: plan.target,
      sizeDiff: plan.sizeDiff,
      colorDiff: plan.colorDiff,
    );
    if (saved.isFailure) {
      await _deleteUnreferencedImages(original, uploadedPaths);
      return Err(saved.getError()!);
    }

    if (plan.removedImagePaths.isNotEmpty) {
      await _deleteImages(original.storeId, plan.removedImagePaths);
    }
    return saved;
  }

  /// A failed update may still have written some colour rows, so only the
  /// uploads the product's current rows do not reference are safe to delete.
  /// Removed images stay: the caller keeps showing [original] after an `Err`.
  Future<void> _deleteUnreferencedImages(
    final Product original,
    final List<String> candidates,
  ) async {
    if (candidates.isEmpty) return;
    final current = await _repository.getProduct(
      storeId: original.storeId,
      productId: original.id,
    );
    if (current.isFailure) {
      AppLogger.warning(
        'Keeping product images $candidates: their references are unknown',
        current.getError(),
      );
      return;
    }
    final referenced = {
      for (final color in current.get()!.colors) ...color.imagePaths,
    };
    final unreferenced = [
      for (final path in candidates)
        if (!referenced.contains(path)) path,
    ];
    if (unreferenced.isNotEmpty) {
      await _deleteImages(original.storeId, unreferenced);
    }
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
