import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/store/data/models/store_order_contact_model.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

part 'store_profile_model.g.dart';

/// [explicitToJson] keeps the nested order contacts plain maps rather than
/// [StoreOrderContactModel] instances, so `jsonDiff` can compare them
/// structurally instead of falling back to identity equality.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class StoreProfileModel {
  const StoreProfileModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.channels,
    this.slug,
    this.address,
    this.latitude,
    this.longitude,
    this.logoPath,
    this.logoUrl,
    this.orderContacts = const [],
  });

  factory StoreProfileModel.fromJson(final Map<String, dynamic> json) =>
      _$StoreProfileModelFromJson(json);

  final String id;
  final String ownerId;
  final String name;
  @JsonKey(includeToJson: false)
  final DateTime createdAt;
  @JsonKey(includeToJson: false)
  final DateTime updatedAt;
  @JsonKey(fromJson: _channelsFromJson)
  final List<StoreChannel> channels;
  final String? slug;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? logoPath;
  @JsonKey(includeToJson: false)
  final String? logoUrl;
  @JsonKey(fromJson: _orderContactsFromJson)
  final List<StoreOrderContactModel> orderContacts;

  Map<String, dynamic> toJson() => _$StoreProfileModelToJson(this);
}

List<StoreChannel> _channelsFromJson(final List<dynamic>? json) =>
    StoreChannel.listFromCodes(json?.whereType<String>());

List<StoreOrderContactModel> _orderContactsFromJson(final List<dynamic>? json) =>
    json
        ?.whereType<Map<String, dynamic>>()
        .where(
          (final e) =>
              e['value'] is String &&
              OrderContactType.fromCode(e['type'] as String?) != null,
        )
        .map(StoreOrderContactModel.fromJson)
        .toList() ??
    const [];
