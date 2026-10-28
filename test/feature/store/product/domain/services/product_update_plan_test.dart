import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_update_plan.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

import '../../../../../support/product_color_fixtures.dart';

void main() {
  final sizeM = ProductSize(
    id: 'm',
    productId: 'p1',
    name: 'M',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final sizeL = ProductSize(
    id: 'l',
    productId: 'p1',
    name: 'L',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
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
        imagePaths: const ['a.jpg', 'b.jpg'],
        imageUrls: const ['https://cdn/a.jpg', 'https://cdn/b.jpg'],
      ),
      productColorFixture(imagePaths: const ['c.jpg'], position: 1),
    ],
    sizes: [sizeM, sizeL],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  const unchangedDraft = ProductDraft(
    name: 'Tee',
    categoryId: 'c1',
    garmentType: GarmentType.top,
    price: 500,
  );
  final keptColors = [
    for (final color in original.colors)
      ColorItem.existing(
        id: color.id,
        name: color.name,
        images: [
          for (final (i, path) in color.imagePaths.indexed)
            ImageItem.existing(path: path, url: color.imageUrls[i]),
        ],
      ),
  ];
  final colorA = original.colors[0];
  final colorB = original.colors[1];
  const keptSizes = [
    SizeItem.existing(id: 'm', name: 'M'),
    SizeItem.existing(id: 'l', name: 'L'),
  ];

  ProductUpdatePlan plan({
    final ProductDraft? draft,
    final List<ColorItem>? colors,
    final List<String> uploadedPaths = const [],
    final List<SizeItem> sizes = keptSizes,
  }) => planProductUpdate(
    original: original,
    draft: draft ?? unchangedDraft,
    colors: colors ?? keptColors,
    uploadedPaths: uploadedPaths,
    sizes: sizes,
  );

  test('an untouched form produces an empty plan', () {
    final result = plan();

    expect(result.isEmpty, isTrue);
    expect(result.removedImagePaths, isEmpty);
  });

  test(
    'a new colour is added at its list position with its uploaded paths',
    () {
      final result = plan(
        colors: [
          ...keptColors,
          ColorItem.newColor(
            name: 'Red',
            images: [File('x.jpg'), File('y.jpg')],
          ),
        ],
        uploadedPaths: const ['new-x.jpg', 'new-y.jpg'],
      );

      expect(result.colorDiff.toAdd.single.position, 2);
      expect(result.colorDiff.toAdd.single.imagePaths, [
        'new-x.jpg',
        'new-y.jpg',
      ]);
      expect(result.colorDiff.toAdd.single.name, 'Red');
      expect(result.colorDiff.toUpdate, isEmpty);
      expect(result.colorDiff.idsToDelete, isEmpty);
    },
  );

  test('a removed colour is deleted and all its images are released', () {
    final result = plan(colors: [keptColors[0]]);

    expect(result.colorDiff.idsToDelete, [colorB.id]);
    expect(result.removedImagePaths, colorB.imagePaths);
  });

  test('a removed image of a kept colour is released', () {
    final result = plan(
      colors: [
        ColorItem.existing(
          id: colorA.id,
          images: const [
            ImageItem.existing(path: 'a.jpg', url: 'https://cdn/a.jpg'),
          ],
        ),
        keptColors[1],
      ],
    );

    expect(result.removedImagePaths, ['b.jpg']);
    expect(result.colorDiff.toUpdate.single.target.imagePaths, ['a.jpg']);
  });

  test('uploads are matched to colours in list order', () {
    final result = plan(
      colors: [
        ColorItem.existing(
          id: colorA.id,
          images: [
            const ImageItem.existing(path: 'a.jpg', url: 'https://cdn/a.jpg'),
            ImageItem.newImage(file: File('x.jpg')),
          ],
        ),
        ColorItem.newColor(name: 'B', images: [File('y.jpg'), File('z.jpg')]),
      ],
      uploadedPaths: const ['u1.jpg', 'u2.jpg', 'u3.jpg'],
    );

    expect(result.colorDiff.toUpdate.single.target.imagePaths, [
      'a.jpg',
      'u1.jpg',
    ]);
    expect(result.colorDiff.toAdd.single.imagePaths, ['u2.jpg', 'u3.jpg']);
    expect(result.colorDiff.toAdd.single.position, 1);
  });

  test('a stale existing colour is skipped and its uploads are released', () {
    final result = plan(
      colors: [
        ...keptColors,
        ColorItem.existing(
          id: 'gone',
          images: [ImageItem.newImage(file: File('x.jpg'))],
        ),
        ColorItem.newColor(images: [File('y.jpg')]),
      ],
      uploadedPaths: const ['stale.jpg', 'fresh.jpg'],
    );

    expect(result.colorDiff.toUpdate, isEmpty);
    expect(result.colorDiff.idsToDelete, isEmpty);
    expect(result.colorDiff.toAdd.single.imagePaths, ['fresh.jpg']);
    expect(result.colorDiff.toAdd.single.position, 3);
    expect(result.removedImagePaths, ['stale.jpg']);
  });

  test('a product without colours gains the new colour', () {
    final result = planProductUpdate(
      original: original.copyWith(colors: const []),
      draft: unchangedDraft,
      colors: [
        ColorItem.newColor(images: [File('x.jpg')]),
      ],
      uploadedPaths: const ['new-x.jpg'],
      sizes: keptSizes,
    );

    expect(result.colorDiff.toAdd.single.imagePaths, ['new-x.jpg']);
    expect(result.colorDiff.toAdd.single.name, isNull);
    expect(result.removedImagePaths, isEmpty);
  });

  test('a draft-only change is a product change without size changes', () {
    final result = plan(draft: unchangedDraft.copyWith(price: 650));

    expect(result.hasProductChanges, isTrue);
    expect(result.target.price, 650);
    expect(result.sizeDiff.isEmpty, isTrue);
    expect(result.colorDiff.isEmpty, isTrue);
  });

  test('a size-only change leaves the product row untouched', () {
    final result = plan(
      sizes: const [
        SizeItem.existing(id: 'm', name: 'M'),
        SizeItem.newSize(name: 'XL'),
      ],
    );

    expect(result.hasProductChanges, isFalse);
    expect(result.sizeDiff.idsToDelete, ['l']);
    expect(result.sizeDiff.toAdd.single.name, 'XL');
    expect(result.isEmpty, isFalse);
  });

  test('a stale existing size is skipped rather than re-inserted', () {
    final result = plan(
      sizes: const [
        ...keptSizes,
        SizeItem.existing(id: 'gone', name: 'S'),
      ],
    );

    expect(result.sizeDiff.isEmpty, isTrue);
  });

  test('mismatched uploaded path count is a programming error', () {
    expect(
      () => plan(
        colors: [
          ColorItem.newColor(images: [File('x.jpg')]),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('a status-only change is a product change', () {
    final result = plan(
      draft: unchangedDraft.copyWith(status: ProductStatus.archived),
    );

    expect(result.hasProductChanges, isTrue);
    expect(result.target.status, ProductStatus.archived);
    expect(result.sizeDiff.isEmpty, isTrue);
  });
}
