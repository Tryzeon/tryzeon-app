import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_storage.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_update_plan.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/create_product.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/delete_product.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/update_product.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRepository implements ProductRepository {
  Result<void, Failure> createResult = const Ok(null);
  Result<void, Failure> updateResult = const Ok(null);
  Result<void, Failure> deleteResult = const Ok(null);
  NewProduct? created;
  ProductUpdatePlan? appliedPlan;
  final List<String> deletedProductIds = [];

  @override
  Future<Result<void, Failure>> createProduct(final NewProduct product) async {
    created = product;
    return createResult;
  }

  @override
  Future<Result<void, Failure>> updateProduct({
    required final Product original,
    required final ProductUpdatePlan plan,
  }) async {
    appliedPlan = plan;
    return updateResult;
  }

  @override
  Future<Result<void, Failure>> deleteProduct({
    required final String storeId,
    required final String productId,
  }) async {
    deletedProductIds.add(productId);
    return deleteResult;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeImageStorage implements ProductImageStorage {
  Result<List<String>, Failure>? uploadResult;
  int uploadCalls = 0;
  final List<String> deleted = [];

  @override
  Future<Result<List<String>, Failure>> upload({
    required final String storeId,
    required final String productId,
    required final List<File> images,
  }) async {
    uploadCalls++;
    return uploadResult ??
        Ok([for (var i = 0; i < images.length; i++) '$productId/new-$i.jpg']);
  }

  @override
  Future<Result<void, Failure>> delete({
    required final String storeId,
    required final List<String> paths,
  }) async {
    deleted.addAll(paths);
    return const Ok(null);
  }
}

void main() {
  late _FakeRepository repository;
  late _FakeImageStorage imageStorage;

  const draft = ProductDraft(
    name: 'Tee',
    categoryId: 'c1',
    garmentType: GarmentType.top,
    price: 500,
  );
  final original = Product(
    id: 'p1',
    storeId: 's1',
    name: 'Tee',
    categoryId: 'c1',
    garmentType: GarmentType.top,
    price: 500,
    imagePaths: const ['a.jpg'],
    imageUrls: const ['https://cdn/a.jpg'],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    repository = _FakeRepository();
    imageStorage = _FakeImageStorage();
  });

  group('CreateProduct', () {
    CreateProduct build() =>
        CreateProduct(repository: repository, imageStorage: imageStorage);
    CreateProductParams params() => CreateProductParams(
      storeId: 's1',
      draft: draft,
      images: [File('x.jpg')],
      sizes: const [],
    );

    test('creates the row with the uploaded paths', () async {
      final result = await build()(params());

      expect(result.isSuccess, isTrue);
      final created = repository.created!;
      expect(created.imagePaths, ['${created.id}/new-0.jpg']);
      expect(imageStorage.deleted, isEmpty);
    });

    test('a failed upload never touches the database', () async {
      imageStorage.uploadResult = const Err(NetworkFailure());

      final result = await build()(params());

      expect(result.getError(), const NetworkFailure());
      expect(repository.created, isNull);
    });

    test('a failed create rolls back the row, then the images', () async {
      repository.createResult = const Err(ServerFailure());

      final result = await build()(params());

      final id = repository.created!.id;
      expect(result.getError(), const ServerFailure());
      expect(repository.deletedProductIds, [id]);
      expect(imageStorage.deleted, ['$id/new-0.jpg']);
    });

    test('a failed rollback keeps the images the row may reference', () async {
      repository
        ..createResult = const Err(ServerFailure())
        ..deleteResult = const Err(NetworkFailure());

      await build()(params());

      expect(imageStorage.deleted, isEmpty);
    });
  });

  group('UpdateProduct', () {
    UpdateProduct build() =>
        UpdateProduct(repository: repository, imageStorage: imageStorage);

    test('an untouched form writes nothing', () async {
      final result = await build()(
        UpdateProductParams(
          original: original,
          draft: draft,
          images: const [
            ImageItem.existing(path: 'a.jpg', url: 'https://cdn/a.jpg'),
          ],
          sizes: const [],
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(imageStorage.uploadCalls, 0);
      expect(repository.appliedPlan, isNull);
    });

    test('replacing an image deletes the old one after the write', () async {
      final result = await build()(
        UpdateProductParams(
          original: original,
          draft: draft,
          images: [ImageItem.newImage(file: File('x.jpg'))],
          sizes: const [],
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(repository.appliedPlan!.target.imagePaths, ['p1/new-0.jpg']);
      expect(imageStorage.deleted, ['a.jpg']);
    });

    test('a failed write discards the new images and keeps the old', () async {
      repository.updateResult = const Err(ServerFailure());

      await build()(
        UpdateProductParams(
          original: original,
          draft: draft,
          images: [ImageItem.newImage(file: File('x.jpg'))],
          sizes: const [],
        ),
      );

      expect(imageStorage.deleted, ['p1/new-0.jpg']);
    });

    test('a failed upload never touches the database', () async {
      imageStorage.uploadResult = const Err(NetworkFailure());

      final result = await build()(
        UpdateProductParams(
          original: original,
          draft: draft,
          images: [ImageItem.newImage(file: File('x.jpg'))],
          sizes: const [],
        ),
      );

      expect(result.getError(), const NetworkFailure());
      expect(repository.appliedPlan, isNull);
    });
  });

  group('DeleteProduct', () {
    DeleteProduct build() =>
        DeleteProduct(repository: repository, imageStorage: imageStorage);

    test('deletes images only after the row is gone', () async {
      final result = await build()(original);

      expect(result.isSuccess, isTrue);
      expect(repository.deletedProductIds, ['p1']);
      expect(imageStorage.deleted, ['a.jpg']);
    });

    test('keeps images when the row delete fails', () async {
      repository.deleteResult = const Err(ServerFailure());

      final result = await build()(original);

      expect(result.getError(), const ServerFailure());
      expect(imageStorage.deleted, isEmpty);
    });
  });
}
