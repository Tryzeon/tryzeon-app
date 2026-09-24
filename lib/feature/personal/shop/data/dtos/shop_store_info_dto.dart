import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/store/data/dtos/store_order_contact_dto.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

part 'shop_store_info_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopStoreInfoDto {
  const ShopStoreInfoDto({
    required this.id,
    required this.name,
    required this.channels,
    this.slug,
    this.address,
    this.logoUrl,
    this.orderContacts = const [],
  });

  factory ShopStoreInfoDto.fromJson(final Map<String, dynamic> json) =>
      _$ShopStoreInfoDtoFromJson(json);

  final String id;
  final String name;
  @JsonKey(fromJson: _channelsFromJson)
  final List<StoreChannel> channels;
  final String? slug;
  final String? address;
  final String? logoUrl;
  @JsonKey(fromJson: _orderContactsFromJson)
  final List<StoreOrderContactDto> orderContacts;

  Map<String, dynamic> toJson() => _$ShopStoreInfoDtoToJson(this);
}

List<StoreChannel> _channelsFromJson(final List<dynamic>? json) =>
    StoreChannel.listFromCodes(json?.whereType<String>());

List<StoreOrderContactDto> _orderContactsFromJson(final List<dynamic>? json) =>
    json
        ?.whereType<Map<String, dynamic>>()
        .where(
          (final e) =>
              e['value'] is String &&
              OrderContactType.fromCode(e['type'] as String?) != null,
        )
        .map(StoreOrderContactDto.fromJson)
        .toList() ??
    const [];
