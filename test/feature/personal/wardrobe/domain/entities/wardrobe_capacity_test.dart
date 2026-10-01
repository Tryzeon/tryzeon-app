import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_capacity.dart';

void main() {
  test('is near the limit from 90% and full at the limit', () {
    const roomy = WardrobeCapacity(used: 17, limit: 20);
    const near = WardrobeCapacity(used: 18, limit: 20);
    const full = WardrobeCapacity(used: 20, limit: 20);

    expect((roomy.isNearLimit, roomy.isFull), (false, false));
    expect((near.isNearLimit, near.isFull), (true, false));
    expect((full.isNearLimit, full.isFull), (true, true));
  });

  test('a zero limit counts as full', () {
    const none = WardrobeCapacity(used: 0, limit: 0);

    expect(none.isFull, isTrue);
    expect(none.usage, 1);
  });
}
