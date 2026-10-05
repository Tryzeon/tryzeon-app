import 'package:tryzeon/core/data/utils/json_diff.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/body_measurement_ranges_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/garment_measurements_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/body_measurement_ranges_mappr.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/garment_measurements_mappr.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_size_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_dto.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_update_plan.dart';
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
  static const _mappr = StoreMappr();

  static GarmentMeasurementsDto? _toMeasurementsDto(
    final GarmentMeasurements? measurements,
  ) {
    if (measurements == null) return null;
    return const GarmentMeasurementsMappr()
        .convert<GarmentMeasurements, GarmentMeasurementsDto>(measurements);
  }

  static BodyMeasurementRangesDto? _toBodyMeasurementRangesDto(
    final BodyMeasurementRanges? bodyMeasurementRanges,
  ) {
    if (bodyMeasurementRanges == null) return null;
    return const BodyMeasurementRangesMappr()
        .convert<BodyMeasurementRanges, BodyMeasurementRangesDto>(
          bodyMeasurementRanges,
        );
  }

  static CreateProductSizeRequest _toSizeRequest(
    final String productId,
    final NewSizeItem size,
  ) {
    return CreateProductSizeRequest(
      productId: productId,
      name: size.name,
      garmentMeasurements: _toMeasurementsDto(size.garmentMeasurements),
      bodyMeasurementRanges: _toBodyMeasurementRangesDto(
        size.bodyMeasurementRanges,
      ),
    );
  }

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
  Future<Result<Product, Failure>> getProductById(
    final String productId,
  ) async {
    try {
      // 1. Try Local Cache
      try {
        final cachedProduct = await _localDataSource.getProductById(productId);
        switch (cachedProduct) {
          case CacheHit<Product>(:final data):
            return Ok(data);
          case CacheEmpty<Product>():
          case CacheMiss<Product>():
            break;
        }
      } catch (e, stackTrace) {
        AppLogger.warning('Local cache read failed', e, stackTrace);
      }

      // 2. Try Remote
      final product = _mappr.convert<ProductDto, Product>(
        await _remoteDataSource.getProduct(productId),
      );

      // 3. Update Cache
      try {
        await _localDataSource.saveProduct(product);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save product to cache', e, stackTrace);
      }

      return Ok(product);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product by ID', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> createProduct(final NewProduct product) async {
    try {
      final draft = product.draft;
      await _remoteDataSource.insertProduct(
        CreateProductRequest(
          id: product.id,
          storeId: product.storeId,
          name: draft.name,
          categoryId: draft.categoryId,
          garmentType: draft.garmentType,
          price: draft.price,
          imagePaths: product.imagePaths,
          gender: draft.gender,
          purchaseLink: draft.purchaseLink,
          description: draft.description,
          material: draft.material,
          elasticity: draft.elasticity,
          fit: draft.fit,
          thickness: draft.thickness,
          styles: switch (draft.styles) {
            final styles? => ClothingStyle.listFromSet(styles),
            null => null,
          },
          seasons: switch (draft.seasons) {
            final seasons? => ProductSeason.listFromSet(seasons),
            null => null,
          },
        ),
      );

      if (product.sizes.isNotEmpty) {
        await _remoteDataSource.insertProductSizes(
          product.sizes
              .map((final size) => _toSizeRequest(product.id, size))
              .toList(),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    await _refreshProduct(storeId: product.storeId, productId: product.id);
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> updateProduct({
    required final Product original,
    required final ProductUpdatePlan plan,
  }) async {
    try {
      final sizeDiff = plan.sizeDiff;

      for (final sizeId in sizeDiff.idsToDelete) {
        await _remoteDataSource.deleteProductSize(sizeId);
      }

      for (final size in sizeDiff.toAdd) {
        await _remoteDataSource.insertProductSize(
          _toSizeRequest(original.id, size),
        );
      }

      for (final update in sizeDiff.toUpdate) {
        final sizeChanges = jsonDiff(
          _mappr.convert<ProductSize, ProductSizeDto>(update.original).toJson(),
          _mappr
              .convert<ProductSize, ProductSizeDto>(update.targetSize)
              .toJson(),
        );
        await _remoteDataSource.updateProductSize(
          update.original.id,
          sizeChanges,
        );
      }

      if (plan.hasProductChanges) {
        final productChanges = jsonDiff(
          _mappr.convert<Product, ProductDto>(original).toJson(),
          _mappr.convert<Product, ProductDto>(plan.target).toJson(),
        );
        if (productChanges.isNotEmpty) {
          await _remoteDataSource.updateProduct(original.id, productChanges);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update product', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    await _refreshProduct(storeId: original.storeId, productId: original.id);
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> setProductStatus({
    required final Product product,
    required final ProductStatus status,
  }) async {
    try {
      await _remoteDataSource.updateProduct(product.id, {
        'status': status.value,
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set product status', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    await _refreshProduct(storeId: product.storeId, productId: product.id);
    return const Ok(null);
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

  Future<void> _refreshProduct({
    required final String storeId,
    required final String productId,
  }) async {
    try {
      await _localDataSource.saveProduct(
        _mappr.convert<ProductDto, Product>(
          await _remoteDataSource.getProduct(productId),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Product refresh failed, invalidating cache',
        e,
        stackTrace,
      );
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
}
