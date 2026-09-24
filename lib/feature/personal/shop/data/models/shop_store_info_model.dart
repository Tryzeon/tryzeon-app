import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/store/data/models/store_order_contact_model.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

part 'shop_store_info_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopStoreInfoModel {
  const ShopStoreInfoModel({
    required this.id,
    required this.name,
    required this.channels,
    this.slug,
    this.address,
    this.logoUrl,
    this.orderContacts = const [],
  });

  factory ShopStoreInfoModel.fromJson(final Map<String, dynamic> json) =>
      _$ShopStoreInfoModelFromJson(json);

  final String id;
  final String name;
  @JsonKey(fromJson: _channelsFromJson)
  final List<StoreChannel> channels;
  final String? slug;
  final String? address;
  final String? logoUrl;
  @JsonKey(fromJson: _orderContactsFromJson)
  final List<StoreOrderContactModel> orderContacts;

  Map<String, dynamic> toJson() => _$ShopStoreInfoModelToJson(this);
}

List<StoreChannel> _channelsFromJson(final List<dynamic>? json) =>
    StoreChannel.listFromCodes(json?.whereType<String>());

List<StoreOrderContactModel> _orderContactsFromJson(final List<dynamic>? json) =>
    json
        ?.whereType<Map<String, dynamic>>()
        .where((final e) => OrderContactType.fromCode(e['type'] as String?) != null)
        .map(StoreOrderContactModel.fromJson)
        .toList() ??
    const [];
