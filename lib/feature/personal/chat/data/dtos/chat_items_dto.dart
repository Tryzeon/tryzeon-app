import 'package:json_annotation/json_annotation.dart';

part 'chat_items_dto.g.dart';

/// Rows stay raw: each is decoded by the owning feature's public row decoder,
/// never by a DTO borrowed from its `data/`.
@JsonSerializable(createToJson: false, checked: true)
class ChatItemsDto {
  const ChatItemsDto({required this.products, required this.wardrobe});

  factory ChatItemsDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatItemsDtoFromJson(json);

  final Map<String, Map<String, dynamic>> products;
  final Map<String, Map<String, dynamic>> wardrobe;
}
