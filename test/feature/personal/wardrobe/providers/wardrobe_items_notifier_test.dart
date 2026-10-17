import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/delete_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/get_wardrobe_items.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/update_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/usecases/upload_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../support/wardrobe_test_doubles.dart';

class _FakeGetWardrobeItems implements GetWardrobeItems {
  var loads = 0;

  @override
  Future<Result<List<WardrobeItem>, Failure>> call({
    final bool forceRefresh = false,
  }) async {
    loads++;
    return Ok([wardrobeItem('a'), wardrobeItem('b'), wardrobeItem('c')]);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeUploadWardrobeItem implements UploadWardrobeItem {
  Result<WardrobeItem, Failure> result = Ok(wardrobeItem('new'));

  @override
  Future<Result<WardrobeItem, Failure>> call(
    final UploadWardrobeItemParams params,
  ) async => result;

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeUpdateWardrobeItem implements UpdateWardrobeItem {
  @override
  Future<Result<WardrobeItem, Failure>> call(
    final UpdateWardrobeItemParams params,
  ) async => Ok(wardrobeItem(params.id, params.garmentType!));

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeDeleteWardrobeItem implements DeleteWardrobeItem {
  @override
  Future<Result<void, Failure>> call(final WardrobeItem item) async =>
      const Ok(null);

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late ProviderContainer container;
  late _FakeGetWardrobeItems getItems;
  late _FakeUploadWardrobeItem upload;

  setUp(() async {
    getItems = _FakeGetWardrobeItems();
    upload = _FakeUploadWardrobeItem();
    container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        getWardrobeItemsUseCaseProvider.overrideWithValue(getItems),
        uploadWardrobeItemUseCaseProvider.overrideWithValue(upload),
        updateWardrobeItemUseCaseProvider.overrideWithValue(
          _FakeUpdateWardrobeItem(),
        ),
        deleteWardrobeItemUseCaseProvider.overrideWithValue(
          _FakeDeleteWardrobeItem(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(wardrobeItemsProvider, (final _, final _) {});
    await container.read(wardrobeItemsProvider.future);
  });

  WardrobeItemsNotifier owner() =>
      container.read(wardrobeItemsProvider.notifier);
  List<String> ids() => [
    for (final item in container.read(wardrobeItemsProvider).value!) item.id,
  ];

  test('uploadItem puts the new item first without refetching', () async {
    await owner().uploadItem(
      UploadWardrobeItemParams(
        image: File('new.jpg'),
        garmentType: GarmentType.top,
      ),
    );

    expect(ids(), ['new', 'a', 'b', 'c']);
    expect(getItems.loads, 1);
  });

  test('updateItem replaces the item in place', () async {
    await owner().updateItem(
      const UpdateWardrobeItemParams(id: 'b', garmentType: GarmentType.pants),
    );

    expect(ids(), ['a', 'b', 'c']);
    expect(
      container.read(wardrobeItemsProvider).value![1].garmentType,
      GarmentType.pants,
    );
  });

  test('deleteItem removes the item', () async {
    await owner().deleteItem(wardrobeItem('b'));

    expect(ids(), ['a', 'c']);
  });

  test('a write that fails leaves the list as it was', () async {
    upload.result = const Err(NetworkFailure());

    final result = await owner().uploadItem(
      UploadWardrobeItemParams(
        image: File('new.jpg'),
        garmentType: GarmentType.top,
      ),
    );

    expect(result.getError(), isA<NetworkFailure>());
    expect(ids(), ['a', 'b', 'c']);
  });
}
