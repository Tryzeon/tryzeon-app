import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/dtos/store_order_contact_dto.dart';
import 'package:tryzeon/feature/common/store/domain/entities/order_contact_type.dart';

/// Rows are written in [OrderContactType] order, so the same contacts always
/// serialize the same and `jsonDiff` sees no change in a mere reordering.
class OrderContactsConverters {
  static Map<OrderContactType, String> fromDtos(
    final List<StoreOrderContactDto> source,
  ) => {for (final contact in source) contact.type: contact.value};

  static List<StoreOrderContactDto> toDtos(
    final Map<OrderContactType, String> source,
  ) => [
    for (final type in OrderContactType.values)
      if (source[type] case final value?)
        StoreOrderContactDto(type: type, value: value),
  ];

  static Map<OrderContactType, String> fromCache(
    final List<StoreOrderContactEmbedded> source,
  ) => {
    for (final contact in source)
      decodeCachedEnum(contact.type, OrderContactType.fromCode): contact.value,
  };

  static List<StoreOrderContactEmbedded> toCache(
    final Map<OrderContactType, String> source,
  ) => [
    for (final type in OrderContactType.values)
      if (source[type] case final value?)
        StoreOrderContactEmbedded()
          ..type = type.code
          ..value = value,
  ];
}
