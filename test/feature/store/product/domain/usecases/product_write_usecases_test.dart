import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/failures/invalid_product_colors_failure.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_diff.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_storage.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_size_diff.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/create_product.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/delete_product.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/set_product_status.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/update_product.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/product_color_fixtures.dart';

class _FakeRepository implements ProductRepository {
  Result<Product?, Failure> createResult = const Ok(null);
  Result<Product?, Failure>? updateResult;
  Result<void, Failure> deleteResult = const Ok(null);
  NewProduct? created;
  Product? appliedTarget;
  ProductSizeDiff? appliedSizeDiff;
  ProductColorDiff? appliedColorDiff;
  final List<String> deletedProductIds = [];

  @override
  Future<Result<Product?, Failure>> createProduct(
    final NewProduct product,
  ) async {
    created = product;
    return createResult;
  }

  @override
  Future<Result<Product?, Failure>> updateProduct({
    required final Product original,
    required final Product target,
    final ProductSizeDiff sizeDiff = const ProductSizeDiff.empty(),
    final ProductColorDiff colorDiff = const ProductColorDiff.empty(),
  }) async {
    appliedTarget = target;
    appliedSizeDiff = sizeDiff;
    appliedColorDiff = colorDiff;
    return updateResult ?? Ok(target);
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
    colors: [
      productColorFixture(
        imagePaths: const ['a.jpg'],
        imageUrls: const ['https://cdn/a.jpg'],
      ).copyWith(name: '黑'),
      productColorFixture(
        imagePaths: const ['b.jpg'],
        position: 1,
      ).copyWith(name: '白'),
    ],
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
      colors: [
        NewColorItem(name: ' 黑 ', images: [File('a.jpg'), File('b.jpg')]),
        NewColorItem(name: '白', images: [File('c.jpg')]),
      ],
      sizes: const [],
    );

    test('creates every colour in order with its own uploaded paths', () async {
      final result = await build()(params());

      expect(result.isSuccess, isTrue);
      expect(imageStorage.uploadCalls, 1);
      final created = repository.created!;
      expect(created.colors, [
        NewProductColor(
          name: '黑',
          imagePaths: ['${created.id}/new-0.jpg', '${created.id}/new-1.jpg'],
          position: 0,
        ),
        NewProductColor(
          name: '白',
          imagePaths: ['${created.id}/new-2.jpg'],
          position: 1,
        ),
      ]);
      expect(imageStorage.deleted, isEmpty);
    });

    test('an invalid colour set fails before uploading', () async {
      final result = await build()(
        CreateProductParams(
          storeId: 's1',
          draft: draft,
          colors: [
            NewColorItem(name: '黑', images: [File('a.jpg')]),
            NewColorItem(images: [File('b.jpg')]),
          ],
          sizes: const [],
        ),
      );

      expect(result.getError(), isA<InvalidProductColorsFailure>());
      expect(imageStorage.uploadCalls, 0);
      expect(repository.created, isNull);
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
      expect(imageStorage.deleted, [
        '$id/new-0.jpg',
        '$id/new-1.jpg',
        '$id/new-2.jpg',
      ]);
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

    const keepA = ExistingColorItem(
      id: 'color-p1-0',
      name: '黑',
      images: [ImageItem.existing(path: 'a.jpg', url: 'https://cdn/a.jpg')],
    );
    const keepB = ExistingColorItem(
      id: 'color-p1-1',
      name: '白',
      images: [ImageItem.existing(path: 'b.jpg', url: 'https://x/b.jpg')],
    );

    UpdateProductParams params(final List<ColorItem> colors) =>
        UpdateProductParams(
          original: original,
          draft: draft,
          colors: colors,
          sizes: const [],
        );

    test('an untouched form writes nothing', () async {
      final result = await build()(params([keepA, keepB]));

      expect(result.get(), original);
      expect(imageStorage.uploadCalls, 0);
      expect(repository.appliedTarget, isNull);
    });

    test(
      'uploads for a colour that no longer exists are released when nothing else changed',
      () async {
        final result = await build()(
          params([
            keepA,
            keepB,
            ExistingColorItem(
              id: 'gone',
              name: '紅',
              images: [ImageItem.newImage(file: File('x.jpg'))],
            ),
          ]),
        );

        expect(result.get(), original);
        expect(repository.appliedTarget, isNull);
        expect(imageStorage.deleted, ['p1/new-0.jpg']);
      },
    );

    test('replacing an image deletes the old one after the write', () async {
      final result = await build()(
        params([
          ExistingColorItem(
            id: 'color-p1-0',
            name: '黑',
            images: [ImageItem.newImage(file: File('x.jpg'))],
          ),
          keepB,
        ]),
      );

      expect(result.isSuccess, isTrue);
      expect(repository.appliedColorDiff!.toUpdate.single.target.imagePaths, [
        'p1/new-0.jpg',
      ]);
      expect(imageStorage.deleted, ['a.jpg']);
    });

    test(
      'deleting a colour releases its images only after the write',
      () async {
        final result = await build()(params([keepA]));

        expect(result.isSuccess, isTrue);
        expect(repository.appliedColorDiff!.idsToDelete, ['color-p1-1']);
        expect(imageStorage.deleted, ['b.jpg']);
      },
    );

    test("a failed write keeps a deleted colour's images and discards new "
        'uploads', () async {
      repository.updateResult = const Err(ServerFailure());

      await build()(
        params([
          ExistingColorItem(
            id: 'color-p1-0',
            name: '黑',
            images: [ImageItem.newImage(file: File('x.jpg'))],
          ),
        ]),
      );

      expect(imageStorage.deleted, ['p1/new-0.jpg']);
    });

    test('a failed upload never touches the database', () async {
      imageStorage.uploadResult = const Err(NetworkFailure());

      final result = await build()(
        params([
          ExistingColorItem(
            id: 'color-p1-0',
            name: '黑',
            images: [ImageItem.newImage(file: File('x.jpg'))],
          ),
          keepB,
        ]),
      );

      expect(result.getError(), const NetworkFailure());
      expect(repository.appliedTarget, isNull);
    });

    test('an invalid colour set fails before uploading', () async {
      final result = await build()(
        params([
          ExistingColorItem(
            id: 'color-p1-0',
            images: [ImageItem.newImage(file: File('x.jpg'))],
          ),
          keepB,
        ]),
      );

      expect(result.getError(), isA<InvalidProductColorsFailure>());
      expect(imageStorage.uploadCalls, 0);
      expect(repository.appliedTarget, isNull);
    });
  });

  group('DeleteProduct', () {
    DeleteProduct build() =>
        DeleteProduct(repository: repository, imageStorage: imageStorage);

    test("deletes every colour's images only after the row is gone", () async {
      final result = await build()(original);

      expect(result.isSuccess, isTrue);
      expect(repository.deletedProductIds, ['p1']);
      expect(imageStorage.deleted, ['a.jpg', 'b.jpg']);
    });

    test('keeps images when the row delete fails', () async {
      repository.deleteResult = const Err(ServerFailure());

      final result = await build()(original);

      expect(result.getError(), const ServerFailure());
      expect(imageStorage.deleted, isEmpty);
    });
  });

  group('SetProductStatus', () {
    test('writes only the status change', () async {
      final result = await SetProductStatus(repository)(
        SetProductStatusParams(
          product: original,
          status: ProductStatus.archived,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(
        repository.appliedTarget,
        original.copyWith(status: ProductStatus.archived),
      );
      expect(repository.appliedSizeDiff!.isEmpty, isTrue);
    });

    test('skips the write when the status is unchanged', () async {
      final result = await SetProductStatus(repository)(
        SetProductStatusParams(product: original, status: original.status),
      );

      expect(result.get(), original);
      expect(repository.appliedTarget, isNull);
    });
  });
}
