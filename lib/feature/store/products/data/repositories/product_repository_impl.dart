import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/shared/measurements/data/mappers/measurements_mappr.dart';
import 'package:tryzeon/core/shared/measurements/data/models/measurements_model.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurements.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_request.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_size_request.dart';
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
  static const _mappr = StoreMappr();

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
  Future<Result<void, Failure>> createProduct(final CreateProductParams params) async {
    try {
      final imagePath = await _remoteDataSource.uploadProductImage(
        storeId: params.storeId,
        image: params.image,
      );

      // Save to local cache
      final bytes = await params.image.readAsBytes();
      await _localDataSource.saveProductImage(bytes, imagePath);

      final request = CreateProductRequest(
        storeId: params.storeId,
        name: params.name,
        categoryId: params.categoryId,
        price: params.price,
        imagePath: imagePath,
        purchaseLink: params.purchaseLink,
        material: params.material,
        elasticity: params.elasticity,
        fit: params.fit,
      );

      final productId = await _remoteDataSource.insertProduct(request);

      final sizesList = params.sizes ?? [];
      if (sizesList.isNotEmpty) {
        final sizeRequests = sizesList
            .map(
              (final size) => CreateProductSizeRequest(
                productId: productId,
                name: size.name,
                measurements: size.measurements != null
                    ? const MeasurementsMappr().convert<Measurements, MeasurementsModel>(
                        size.measurements!,
                      )
                    : null,
              ),
            )
            .toList();
        await _remoteDataSource.insertProductSizes(sizeRequests);
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
            final sizeRequest = CreateProductSizeRequest(
              productId: original.id,
              name: targetSize.name,
              measurements: targetSize.measurements != null
                  ? const MeasurementsMappr().convert<Measurements, MeasurementsModel>(
                      targetSize.measurements!,
                    )
                  : null,
            );
            await _remoteDataSource.insertProductSize(sizeRequest);
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
