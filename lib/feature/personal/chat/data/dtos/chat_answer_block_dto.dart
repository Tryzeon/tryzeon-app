// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_answer_block_dto.freezed.dart';
part 'chat_answer_block_dto.g.dart';

/// `item` stays a raw row: it is decoded by the owning feature's public row
/// decoder, never by a DTO borrowed from its `data/`.
@Freezed(
  unionKey: 'type',
  unionValueCase: FreezedUnionCase.snake,
  fallbackUnion: 'unknown',
  toJson: false,
)
sealed class ChatAnswerBlockDto with _$ChatAnswerBlockDto {
  @JsonSerializable(createToJson: false, checked: true)
  const factory ChatAnswerBlockDto.text({required final String text}) =
      ChatAnswerTextDto;

  @JsonSerializable(createToJson: false, checked: true)
  const factory ChatAnswerBlockDto.product({
    required final Map<String, dynamic> item,
  }) = ChatAnswerProductDto;

  @JsonSerializable(createToJson: false, checked: true)
  const factory ChatAnswerBlockDto.wardrobe({
    required final Map<String, dynamic> item,
  }) = ChatAnswerWardrobeDto;

  const factory ChatAnswerBlockDto.unknown() = ChatAnswerUnknownDto;

  factory ChatAnswerBlockDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatAnswerBlockDtoFromJson(json);
}
