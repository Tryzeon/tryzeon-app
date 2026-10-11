import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_capacity.dart';

void main() {
  test('is near the limit from 90%', () {
    const roomy = WardrobeCapacity(used: 17, limit: 20);
    const near = WardrobeCapacity(used: 18, limit: 20);

    expect(roomy.isNearLimit, isFalse);
    expect(near.isNearLimit, isTrue);
  });

  test('a zero limit reads as fully used', () {
    const none = WardrobeCapacity(used: 0, limit: 0);

    expect(none.usage, 1);
  });
}
