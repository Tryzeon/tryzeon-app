import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_update_plan.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

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
    imagePaths: const ['a.jpg', 'b.jpg'],
    imageUrls: const ['https://cdn/a.jpg', 'https://cdn/b.jpg'],
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
  const keptImages = [
    ImageItem.existing(path: 'a.jpg', url: 'https://cdn/a.jpg'),
    ImageItem.existing(path: 'b.jpg', url: 'https://cdn/b.jpg'),
  ];
  const keptSizes = [
    SizeItem.existing(id: 'm', name: 'M'),
    SizeItem.existing(id: 'l', name: 'L'),
  ];

  test('an untouched form produces an empty plan', () {
    final plan = planProductUpdate(
      original: original,
      draft: unchangedDraft,
      images: keptImages,
      uploadedPaths: const [],
      sizes: keptSizes,
    );

    expect(plan.isEmpty, isTrue);
    expect(plan.removedImagePaths, isEmpty);
  });

  test(
    'interleaves uploaded paths into the user order and reports removals',
    () {
      final plan = planProductUpdate(
        original: original,
        draft: unchangedDraft,
        images: [
          ImageItem.newImage(file: File('x.jpg')),
          const ImageItem.existing(path: 'b.jpg', url: 'https://cdn/b.jpg'),
          ImageItem.newImage(file: File('y.jpg')),
        ],
        uploadedPaths: const ['new-x.jpg', 'new-y.jpg'],
        sizes: keptSizes,
      );

      expect(plan.target.imagePaths, ['new-x.jpg', 'b.jpg', 'new-y.jpg']);
      expect(plan.removedImagePaths, ['a.jpg']);
      expect(plan.hasProductChanges, isTrue);
    },
  );

  test('a draft-only change is a product change without size changes', () {
    final plan = planProductUpdate(
      original: original,
      draft: unchangedDraft.copyWith(price: 650),
      images: keptImages,
      uploadedPaths: const [],
      sizes: keptSizes,
    );

    expect(plan.hasProductChanges, isTrue);
    expect(plan.target.price, 650);
    expect(plan.sizeDiff.isEmpty, isTrue);
  });

  test('a size-only change leaves the product row untouched', () {
    final plan = planProductUpdate(
      original: original,
      draft: unchangedDraft,
      images: keptImages,
      uploadedPaths: const [],
      sizes: const [
        SizeItem.existing(id: 'm', name: 'M'),
        SizeItem.newSize(name: 'XL'),
      ],
    );

    expect(plan.hasProductChanges, isFalse);
    expect(plan.sizeDiff.idsToDelete, ['l']);
    expect(plan.sizeDiff.toAdd.single.name, 'XL');
    expect(plan.isEmpty, isFalse);
  });

  test('a stale existing size is skipped rather than re-inserted', () {
    final plan = planProductUpdate(
      original: original,
      draft: unchangedDraft,
      images: keptImages,
      uploadedPaths: const [],
      sizes: const [
        ...keptSizes,
        SizeItem.existing(id: 'gone', name: 'S'),
      ],
    );

    expect(plan.sizeDiff.isEmpty, isTrue);
  });

  test('mismatched uploaded path count is a programming error', () {
    expect(
      () => planProductUpdate(
        original: original,
        draft: unchangedDraft,
        images: [ImageItem.newImage(file: File('x.jpg'))],
        uploadedPaths: const [],
        sizes: keptSizes,
      ),
      throwsArgumentError,
    );
  });
}
