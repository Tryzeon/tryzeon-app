import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/data/utils/json_diff.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/product_color/data/dtos/product_color_dto.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_size_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_dto.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_size_draft_dto.dart';
import 'package:tryzeon/feature/store/product/data/mappers/create_product_color_requests.dart';
import 'package:tryzeon/feature/store/product/data/mappers/store_product_mappr.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_diff.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_size_diff.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';
import 'package:typed_result/typed_result.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required final ProductRemoteDataSource remoteDataSource,
    required final ProductLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  static const _mappr = StoreProductMappr();

  static CreateProductSizeRequest _sizeRequest(
    final String productId,
    final NewSizeItem size,
  ) => CreateProductSizeRequest(
    productId: productId,
    size: _mappr.convert<NewSizeItem, ProductSizeDraftDto>(size),
  );

  @override
  Future<Result<List<Product>, Failure>> listProducts({
    required final String storeId,
    final bool forceRefresh = false,
  }) async {
    try {
      // 1. Try Local Cache
      if (!forceRefresh) {
        try {
          final cachedProducts = await _localDataSource.listProducts(
            storeId: storeId,
          );
          switch (cachedProducts) {
            case CacheHit<List<Product>>(:final data):
              return Ok(data);
            case CacheEmpty<List<Product>>():
              return const Ok([]);
            case CacheMiss<List<Product>>():
              break;
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
      final products = _mappr.convertList<ProductDto, Product>(
        await _remoteDataSource.listProducts(storeId: storeId),
      );

      // 3. Update Cache
      try {
        await _localDataSource.saveProducts(storeId, products);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save products to cache', e, stackTrace);
      }

      return Ok(products);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load product list', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Product?, Failure>> createProduct(
    final NewProduct product,
  ) async {
    try {
      await _remoteDataSource.insertProduct(
        _mappr.convert<NewProduct, CreateProductRequest>(product),
      );

      if (product.colors.isNotEmpty) {
        await _remoteDataSource.insertProductColors(
          toCreateProductColorRequests(
            productId: product.id,
            storeId: product.storeId,
            colors: product.colors,
          ),
        );
      }

      if (product.sizes.isNotEmpty) {
        await _remoteDataSource.insertProductSizes([
          for (final size in product.sizes) _sizeRequest(product.id, size),
        ]);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    return Ok(
      await _refreshProduct(storeId: product.storeId, productId: product.id),
    );
  }

  @override
  Future<Result<Product?, Failure>> updateProduct({
    required final Product original,
    required final Product target,
    final ProductSizeDiff sizeDiff = const ProductSizeDiff.empty(),
    final ProductColorDiff colorDiff = const ProductColorDiff.empty(),
  }) async {
    try {
      for (final sizeId in sizeDiff.idsToDelete) {
        await _remoteDataSource.deleteProductSize(sizeId);
      }

      for (final size in sizeDiff.toAdd) {
        await _remoteDataSource.insertProductSize(
          _sizeRequest(original.id, size),
        );
      }

      for (final update in sizeDiff.toUpdate) {
        final sizeChanges = jsonDiff(
          _mappr.convert<ProductSize, ProductSizeDto>(update.original).toJson(),
          _mappr
              .convert<ProductSize, ProductSizeDto>(update.targetSize)
              .toJson(),
        );
        if (sizeChanges.isNotEmpty) {
          await _remoteDataSource.updateProductSize(
            update.original.id,
            sizeChanges,
          );
        }
      }

      final productChanges = jsonDiff(
        _mappr.convert<Product, ProductDto>(original).toJson(),
        _mappr.convert<Product, ProductDto>(target).toJson(),
      );
      if (productChanges.isNotEmpty) {
        await _remoteDataSource.updateProduct(original.id, productChanges);
      }

      for (final colorId in colorDiff.idsToDelete) {
        await _remoteDataSource.deleteProductColor(colorId);
      }

      // The (product_id, name) unique index is not deferrable, so a rename or
      // swap would collide mid-way unless every old name is released first.
      for (final update in colorDiff.toUpdate) {
        if (update.original.name != null &&
            update.original.name != update.target.name) {
          await _remoteDataSource.updateProductColor(update.original.id, {
            'name': null,
          });
        }
      }

      for (final update in colorDiff.toUpdate) {
        final colorChanges = jsonDiff(
          _mappr
              .convert<ProductColor, ProductColorDto>(update.original)
              .toJson(),
          _mappr.convert<ProductColor, ProductColorDto>(update.target).toJson(),
        );
        if (colorChanges.isNotEmpty) {
          await _remoteDataSource.updateProductColor(
            update.original.id,
            colorChanges,
          );
        }
      }

      if (colorDiff.toAdd.isNotEmpty) {
        await _remoteDataSource.insertProductColors(
          toCreateProductColorRequests(
            productId: original.id,
            storeId: original.storeId,
            colors: colorDiff.toAdd,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    return Ok(
      await _refreshProduct(storeId: original.storeId, productId: original.id),
    );
  }

  @override
  Future<Result<void, Failure>> deleteProduct({
    required final String storeId,
    required final String productId,
  }) async {
    try {
      await _remoteDataSource.deleteProduct(productId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    try {
      await _localDataSource.deleteProduct(
        storeId: storeId,
        productId: productId,
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to evict deleted product from cache',
        e,
        stackTrace,
      );
    }
    return const Ok(null);
  }

  /// Null when the row was written but reading it back failed; the cache is
  /// invalidated so the next read refetches.
  Future<Product?> _refreshProduct({
    required final String storeId,
    required final String productId,
  }) async {
    final Product product;
    try {
      product = _mappr.convert<ProductDto, Product>(
        await _remoteDataSource.getProduct(productId),
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Product read-back failed, invalidating cache',
        e,
        stackTrace,
      );
      await _invalidate(storeId: storeId, productId: productId);
      return null;
    }

    try {
      await _localDataSource.saveProduct(product);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to cache the product, invalidating cache',
        e,
        stackTrace,
      );
      await _invalidate(storeId: storeId, productId: productId);
    }
    return product;
  }

  Future<void> _invalidate({
    required final String storeId,
    required final String productId,
  }) async {
    try {
      await _localDataSource.invalidateProduct(
        storeId: storeId,
        productId: productId,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to invalidate product cache', e, stackTrace);
    }
  }
}
