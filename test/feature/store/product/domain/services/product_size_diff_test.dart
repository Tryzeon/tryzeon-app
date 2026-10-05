import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_size_diff.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

void main() {
  final sizeM = ProductSize(
    id: 'm',
    productId: 'p1',
    name: 'M',
    garmentMeasurements: const GarmentMeasurements(length: 70),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026, 2),
  );

  const unchangedM = SizeItem.existing(
    id: 'm',
    name: 'M',
    garmentMeasurements: GarmentMeasurements(length: 70),
  );

  test('a new size is added', () {
    final diff = computeSizeDiff(
      [sizeM],
      const [unchangedM, SizeItem.newSize(name: 'L')],
    );

    expect(diff.toAdd, const [SizeItem.newSize(name: 'L')]);
    expect(diff.toUpdate, isEmpty);
    expect(diff.idsToDelete, isEmpty);
  });

  test('an original size missing from the target is deleted', () {
    final diff = computeSizeDiff([sizeM], const []);

    expect(diff.idsToDelete, ['m']);
    expect(diff.toAdd, isEmpty);
    expect(diff.toUpdate, isEmpty);
  });

  test('a renamed size updates only the name and keeps the row identity', () {
    final diff = computeSizeDiff(
      [sizeM],
      const [
        SizeItem.existing(
          id: 'm',
          name: 'Medium',
          garmentMeasurements: GarmentMeasurements(length: 70),
        ),
      ],
    );

    final update = diff.toUpdate.single;
    expect(update.targetSize.name, 'Medium');
    expect(update.targetSize.id, sizeM.id);
    expect(update.targetSize.productId, sizeM.productId);
    expect(update.targetSize.createdAt, sizeM.createdAt);
    expect(update.targetSize.garmentMeasurements, sizeM.garmentMeasurements);
  });

  test('changed garment measurements produce an update', () {
    final diff = computeSizeDiff(
      [sizeM],
      const [
        SizeItem.existing(
          id: 'm',
          name: 'M',
          garmentMeasurements: GarmentMeasurements(length: 72),
        ),
      ],
    );

    final update = diff.toUpdate.single;
    expect(
      update.targetSize.garmentMeasurements,
      const GarmentMeasurements(length: 72),
    );
  });

  test('an unchanged size produces an empty diff', () {
    final diff = computeSizeDiff([sizeM], const [unchangedM]);

    expect(diff.toUpdate, isEmpty);
    expect(diff.isEmpty, isTrue);
  });

  test('a product without sizes only adds', () {
    final diff = computeSizeDiff(null, const [SizeItem.newSize(name: 'S')]);

    expect(diff.toAdd, const [SizeItem.newSize(name: 'S')]);
    expect(diff.idsToDelete, isEmpty);
  });
}
