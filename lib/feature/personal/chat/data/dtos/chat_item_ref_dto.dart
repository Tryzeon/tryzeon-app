// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_item_ref_dto.freezed.dart';
part 'chat_item_ref_dto.g.dart';

@Freezed(
  unionKey: 'type',
  unionValueCase: FreezedUnionCase.snake,
  fallbackUnion: 'unknown',
)
sealed class ChatItemRefDto with _$ChatItemRefDto {
  @JsonSerializable(checked: true, includeIfNull: false)
  const factory ChatItemRefDto.product({
    required final String id,
    final String? colorId,
  }) = ChatProductRefDto;

  @JsonSerializable(checked: true)
  const factory ChatItemRefDto.wardrobe({required final String id}) =
      ChatWardrobeRefDto;

  const factory ChatItemRefDto.unknown() = ChatUnknownRefDto;

  factory ChatItemRefDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatItemRefDtoFromJson(json);
}
