import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_store_info_dto.dart';

void main() {
  test('drops order contacts with an unknown type or a missing value', () {
    final model = ShopStoreInfoDto.fromJson({
      'id': 's1',
      'name': '小店',
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
