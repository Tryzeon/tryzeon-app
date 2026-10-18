import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/dtos/store_order_contact_dto.dart';
import 'package:tryzeon/feature/common/store/data/mappers/order_contacts_converters.dart';
import 'package:tryzeon/feature/common/store/domain/entities/order_contact_type.dart';

void main() {
  const contacts = {
    OrderContactType.instagram: '@ig',
    OrderContactType.line: '@line',
  };

  test('contacts are sent in channel order, whatever order they were set', () {
    expect(
      OrderContactsConverters.toDtos(
        contacts,
      ).map((final dto) => dto.toJson()).toList(),
      [
        {'type': 'line', 'value': '@line'},
        {'type': 'instagram', 'value': '@ig'},
      ],
    );
  });

  test('rows read back as one value per channel', () {
    expect(
      OrderContactsConverters.fromDtos(const [
        StoreOrderContactDto(type: OrderContactType.line, value: '@line'),
        StoreOrderContactDto(type: OrderContactType.instagram, value: '@ig'),
      ]),
      contacts,
    );
  });

  test('contacts survive a round trip through the cache', () {
    expect(
      OrderContactsConverters.fromCache(
        OrderContactsConverters.toCache(contacts),
      ),
      contacts,
    );
  });

  test('a cached channel this client no longer knows fails to decode', () {
    expect(
      () => OrderContactsConverters.fromCache([
        StoreOrderContactEmbedded()
          ..type = 'threads'
          ..value = '@shop',
      ]),
      throwsA(isA<CacheDecodeException>()),
    );
  });
}
