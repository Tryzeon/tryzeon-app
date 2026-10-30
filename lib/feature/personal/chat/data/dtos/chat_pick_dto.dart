// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_pick_dto.freezed.dart';
part 'chat_pick_dto.g.dart';

@Freezed(
  unionKey: 'type',
  unionValueCase: FreezedUnionCase.snake,
  fallbackUnion: 'unknown',
)
sealed class ChatPickDto with _$ChatPickDto {
  @JsonSerializable(checked: true, includeIfNull: false)
  const factory ChatPickDto.product({
    required final String id,
    final String? highlight,
    final String? colorId,
  }) = ChatProductPickDto;

  @JsonSerializable(checked: true, includeIfNull: false)
  const factory ChatPickDto.wardrobe({
    required final String id,
    final String? highlight,
  }) = ChatWardrobePickDto;

  const factory ChatPickDto.unknown() = ChatUnknownPickDto;

  factory ChatPickDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatPickDtoFromJson(json);
}
