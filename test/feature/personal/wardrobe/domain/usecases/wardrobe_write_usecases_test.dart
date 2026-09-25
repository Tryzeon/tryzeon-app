import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/wardrobe_image_storage.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/delete_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/upload_wardrobe_item.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

class _FakeRepository implements WardrobeRepository {
  Result<void, Failure> createResult = const Ok(null);
  Result<void, Failure> deleteResult = const Ok(null);
  String? createdImagePath;
  final List<String> deletedIds = [];

  @override
  Future<Result<void, Failure>> createWardrobeItem({
    required final String id,
    required final String imagePath,
    required final GarmentType garmentType,
    required final List<String> tags,
  }) async {
    createdImagePath = imagePath;
    return createResult;
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

  @override
  Future<Result<String, Failure>> upload({
    required final File image,
    required final GarmentType garmentType,
  }) async => const Ok('u1/top/new.jpg');

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
      params: CreateWardrobeItemParams(
        image: File('a.jpg'),
        garmentType: GarmentType.top,
      ),
      currentItemCount: 0,
      wardrobeLimit: 10,
    );

    test('a full wardrobe uploads nothing', () async {
      final result = await build()(
        params: CreateWardrobeItemParams(
          image: File('a.jpg'),
          garmentType: GarmentType.top,
        ),
        currentItemCount: 10,
        wardrobeLimit: 10,
      );

      expect(result.getError(), isA<ValidationFailure>());
      expect(repository.createdImagePath, isNull);
    });

    test('creates the item with the uploaded path', () async {
      final result = await upload();

      expect(result.isSuccess, isTrue);
      expect(repository.createdImagePath, 'u1/top/new.jpg');
    });

    test('a failed create discards the uploaded image', () async {
      repository.createResult = const Err(ServerFailure());

      await upload();

      expect(imageStorage.deleted, ['u1/top/new.jpg']);
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
