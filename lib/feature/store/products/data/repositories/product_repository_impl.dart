import 'dart:io';

import 'package:tryzeon/app_mappr.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:typed_result/typed_result.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required final ProductRemoteDataSource remoteDataSource,
    required final ProductLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  static const _mappr = AppMappr();

  @override
  Future<Result<List<Product>, Failure>> getProducts({
    required final String storeId,
    final SortCondition sort = SortCondition.defaultSort,
    final bool forceRefresh = false,
  }) async {
    // 1. Try Local Cache
    if (!forceRefresh) {
      try {
        final cachedProducts = await _localDataSource.getProducts(sort: sort);
        if (cachedProducts != null) {
          return Ok(_mappr.convertList<ProductModel, Product>(cachedProducts));
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Local cache read failed, falling back to remote',
          e,
          stackTrace,
        );
      }
    }

    // 2. Try Remote
    try {
      final remoteProducts = await _remoteDataSource.getProducts(
        storeId: storeId,
        sort: sort,
      );

      // 3. Update Cache
      try {
        await _localDataSource.saveProducts(remoteProducts);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save products to cache', e, stackTrace);
      }

      final products = _mappr.convertList<ProductModel, Product>(remoteProducts);
      return Ok(products);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load product list', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> createProduct({
    required final Product product,
    required final File image,
  }) async {
    try {
      final imagePath = await _remoteDataSource.uploadProductImage(
        storeId: product.storeId,
        image: image,
      );

      // Save to local cache
      final bytes = await image.readAsBytes();
      await _localDataSource.saveProductImage(bytes, imagePath);

      final productModel = ProductModel(
        storeId: product.storeId,
        name: product.name,
        categories: product.categories,
        price: product.price,
        imagePath: imagePath,
        imageUrl: '',
        purchaseLink: product.purchaseLink,
        material: product.material,
        elasticity: product.elasticity,
        fit: product.fit,
        id: product.id,
      );

      final productId = await _remoteDataSource.insertProduct(productModel);

      final sizes = product.sizes ?? [];
      if (sizes.isNotEmpty) {
        final sizeModels = sizes.map((final size) {
          final sizeModel = _mappr.convert<ProductSize, ProductSizeModel>(
            size.copyWith(productId: productId),
          );
          return sizeModel;
        }).toList();
        await _remoteDataSource.insertProductSizes(sizeModels);
      }

      final model = await _remoteDataSource.getProduct(productId);

      final currentCache =
          await _localDataSource.getProducts(sort: SortCondition.defaultSort) ?? [];
      await _localDataSource.saveProducts([model, ...currentCache]);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Fail to create product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateProduct({
    required final Product original,
    required final Product target,
    final File? newImage,
  }) async {
    try {
      Product finalTarget = target;
      if (newImage != null) {
        final newImagePath = await _remoteDataSource.uploadProductImage(
          storeId: target.storeId,
          image: newImage,
        );
        finalTarget = target.copyWith(imagePath: newImagePath);

        // Save to local cache
        final bytes = await newImage.readAsBytes();
        await _localDataSource.saveProductImage(bytes, newImagePath);
      }

      final productChanged = original != finalTarget;
      final sizesChanged = original.sizes != target.sizes;

      if (!productChanged && !sizesChanged && newImage == null) {
        return const Ok(null);
      }

      if (productChanged) {
        final targetModel = _mappr.convert<Product, ProductModel>(finalTarget);
        await _remoteDataSource.updateProduct(targetModel);
      }

      if (newImage != null) {
        _remoteDataSource.deleteProductImage(original.imagePath).ignore();
        _localDataSource.deleteProductImage(original.imagePath).ignore();
      }

      if (sizesChanged) {
        final originalSizes = original.sizes ?? [];
        final targetSizes = target.sizes ?? [];

        final targetSizeIds = targetSizes
            .map((final s) => s.id)
            .whereType<String>()
            .toSet();

        // Delete removed sizes
        for (final originalSize in originalSizes) {
          if (originalSize.id.isNotEmpty && !targetSizeIds.contains(originalSize.id)) {
            await _remoteDataSource.deleteProductSize(originalSize.id);
          }
        }

        // Add new sizes
        for (final targetSize in targetSizes) {
          if (targetSize.id.isEmpty) {
            final sizeModel = _mappr.convert<ProductSize, ProductSizeModel>(
              targetSize.copyWith(productId: original.id),
            );
            await _remoteDataSource.insertProductSize(sizeModel);
          } else {
            // Update existing sizes if changed
            final originalSize = originalSizes.cast<ProductSize?>().firstWhere(
              (final s) => s?.id == targetSize.id,
              orElse: () => null,
            );

            if (originalSize != null && originalSize != targetSize) {
              final sizeModel = _mappr.convert<ProductSize, ProductSizeModel>(targetSize);
              await _remoteDataSource.updateProductSize(sizeModel);
            }
          }
        }
      }

      final model = await _remoteDataSource.getProduct(original.id);

      final currentCache =
          await _localDataSource.getProducts(sort: SortCondition.defaultSort) ?? [];
      await _localDataSource.saveProducts(
        currentCache.map((final p) => p.id == model.id ? model : p).toList(),
      );

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Fail to update product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> deleteProduct(final Product product) async {
    try {
      await _remoteDataSource.deleteProduct(product.id);
      await _remoteDataSource.deleteProductSizes(product.id);

      if (product.imagePath.isNotEmpty) {
        _remoteDataSource.deleteProductImage(product.imagePath).ignore();
        _localDataSource.deleteProductImage(product.imagePath).ignore();
      }

      final currentCache =
          await _localDataSource.getProducts(sort: SortCondition.defaultSort) ?? [];
      await _localDataSource.saveProducts(
        currentCache.where((final p) => p.id != product.id).toList(),
      );

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Fail to delete product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
