import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

part 'store_order_contact_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StoreOrderContactDto {
  const StoreOrderContactDto({required this.type, required this.value});

  factory StoreOrderContactDto.fromJson(final Map<String, dynamic> json) =>
      _$StoreOrderContactDtoFromJson(json);

  final OrderContactType type;
  final String value;

  Map<String, dynamic> toJson() => _$StoreOrderContactDtoToJson(this);
}
