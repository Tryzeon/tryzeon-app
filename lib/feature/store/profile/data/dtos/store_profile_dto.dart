import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/store/data/dtos/store_order_contact_dto.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

part 'store_profile_dto.g.dart';

/// [explicitToJson] keeps the nested order contacts plain maps rather than
/// [StoreOrderContactDto] instances, so `jsonDiff` can compare them
/// structurally instead of falling back to identity equality.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class StoreProfileDto {
  const StoreProfileDto({
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
    this.orderContacts = const [],
  });

  factory StoreProfileDto.fromJson(final Map<String, dynamic> json) =>
      _$StoreProfileDtoFromJson(json);

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
  @JsonKey(fromJson: _orderContactsFromJson)
  final List<StoreOrderContactDto> orderContacts;

  Map<String, dynamic> toJson() => _$StoreProfileDtoToJson(this);
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
