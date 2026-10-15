// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_recommended_item_dto.dart';

part 'chat_content_block_dto.freezed.dart';
part 'chat_content_block_dto.g.dart';

/// One shape both ways: the server's transcript is stored and sent back as is.
@Freezed(
  unionKey: 'type',
  unionValueCase: FreezedUnionCase.snake,
  fallbackUnion: 'unknown',
)
sealed class ChatContentBlockDto with _$ChatContentBlockDto {
  @JsonSerializable(checked: true)
  const factory ChatContentBlockDto.text({required final String text}) =
      ChatTextBlockDto;

  @JsonSerializable(checked: true)
  const factory ChatContentBlockDto.toolUse({
    required final String id,
    required final String name,
    required final Map<String, dynamic> input,
  }) = ChatToolUseBlockDto;

  @JsonSerializable(checked: true)
  const factory ChatContentBlockDto.toolResult({
    @JsonKey(name: 'tool_use_id') required final String toolUseId,
    required final Map<String, dynamic> content,
  }) = ChatToolResultBlockDto;

  @JsonSerializable(checked: true, explicitToJson: true)
  const factory ChatContentBlockDto.recommendation({
    required final List<ChatRecommendedItemDto> items,
  }) = ChatRecommendationBlockDto;

  const factory ChatContentBlockDto.unknown() = ChatUnknownBlockDto;

  factory ChatContentBlockDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatContentBlockDtoFromJson(json);
}
