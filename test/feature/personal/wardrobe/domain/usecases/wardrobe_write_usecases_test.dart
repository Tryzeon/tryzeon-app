import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/new_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/wardrobe_image_storage.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/delete_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/upload_wardrobe_item.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

class _FakeRepository implements WardrobeRepository {
  Result<WardrobeItem, Failure>? createResult;
  Result<void, Failure> deleteResult = const Ok(null);
  String? createdImagePath;
  String? createdId;
  final List<String> deletedIds = [];

  @override
  Future<Result<WardrobeItem, Failure>> createWardrobeItem(
    final NewWardrobeItem item,
  ) async {
    createdImagePath = item.imagePath;
    createdId = item.id;
    return createResult ??
        Ok(
          WardrobeItem(
            id: item.id,
            imagePath: item.imagePath,
            garmentType: item.garmentType,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
            tags: item.tags,
          ),
        );
  }

  @override
  Future<Result<void, Failure>> deleteWardrobeItem(final String id) async {
    deletedIds.add(id);
    return deleteResult;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeImageStorage implements WardrobeImageStorage {
  final List<String> deleted = [];
  String? uploadedItemId;

  @override
  Future<Result<String, Failure>> upload({
    required final String itemId,
    required final File image,
  }) async {
    uploadedItemId = itemId;
    return const Ok('u1/new.jpg');
  }

  @override
  Future<Result<void, Failure>> delete(final String path) async {
    deleted.add(path);
    return const Ok(null);
  }
}

void main() {
  late _FakeRepository repository;
  late _FakeImageStorage imageStorage;

  setUp(() {
    repository = _FakeRepository();
    imageStorage = _FakeImageStorage();
  });

  group('UploadWardrobeItem', () {
    UploadWardrobeItem build() =>
        UploadWardrobeItem(repository: repository, imageStorage: imageStorage);
    Future<Result<void, Failure>> upload() => build()(
      UploadWardrobeItemParams(
        image: File('a.jpg'),
        garmentType: GarmentType.top,
      ),
    );

    test('creates the item with the uploaded path', () async {
      final result = await upload();

      expect(result.isSuccess, isTrue);
      expect(repository.createdImagePath, 'u1/new.jpg');
    });

    test('names the image after the item it creates', () async {
      await upload();

      expect(imageStorage.uploadedItemId, isNotNull);
      expect(repository.createdId, imageStorage.uploadedItemId);
    });

    test('a failed create discards the uploaded image', () async {
      repository.createResult = const Err(ServerFailure());

      await upload();

      expect(imageStorage.deleted, ['u1/new.jpg']);
    });
  });

  group('DeleteWardrobeItem', () {
    DeleteWardrobeItem build() =>
        DeleteWardrobeItem(repository: repository, imageStorage: imageStorage);

    test('deletes the image after the row', () async {
      final result = await build()(wardrobeItem('w1'));

      expect(result.isSuccess, isTrue);
      expect(repository.deletedIds, ['w1']);
      expect(imageStorage.deleted, ['w1.jpg']);
    });

    test('keeps the image when the row delete fails', () async {
      repository.deleteResult = const Err(ServerFailure());

      await build()(wardrobeItem('w1'));

      expect(imageStorage.deleted, isEmpty);
    });
  });
}
