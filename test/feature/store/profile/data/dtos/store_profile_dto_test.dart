import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/store/profile/data/dtos/store_profile_dto.dart';

void main() {
  test('drops order contacts with an unknown type or a missing value', () {
    final model = StoreProfileDto.fromJson({
      'id': 's1',
      'owner_id': 'u1',
      'name': '小店',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'channels': const <String>[],
      'order_contacts': [
        {'type': 'line', 'value': '@shop'},
        {'type': 'line_oa', 'value': '@shop'},
        {'type': 'instagram'},
        {'type': 'facebook', 'value': null},
      ],
    });

    expect(model.orderContacts.single.type, OrderContactType.line);
    expect(model.orderContacts.single.value, '@shop');
  });
}
