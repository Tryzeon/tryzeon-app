// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_items_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_message_dto.dart';

part 'chat_stream_event_dto.freezed.dart';
part 'chat_stream_event_dto.g.dart';

@Freezed(
  unionKey: 'type',
  unionValueCase: FreezedUnionCase.snake,
  fallbackUnion: 'unknown',
  toJson: false,
)
sealed class ChatStreamEventDto with _$ChatStreamEventDto {
  @JsonSerializable(createToJson: false, checked: true)
  const factory ChatStreamEventDto.toolUse({
    required final String id,
    required final String name,
    required final Map<String, dynamic> input,
  }) = ChatToolUseEventDto;

  @JsonSerializable(createToJson: false, checked: true)
  const factory ChatStreamEventDto.toolResult({
    @JsonKey(name: 'tool_use_id') required final String toolUseId,
    required final Map<String, dynamic> content,
  }) = ChatToolResultEventDto;

  @JsonSerializable(createToJson: false, checked: true)
  const factory ChatStreamEventDto.done({
    required final List<ChatMessageDto> messages,
    required final ChatItemsDto items,
  }) = ChatDoneEventDto;

  @JsonSerializable(createToJson: false, checked: true)
  const factory ChatStreamEventDto.error({
    required final String code,
    final String? message,
  }) = ChatErrorEventDto;

  const factory ChatStreamEventDto.unknown() = ChatUnknownEventDto;

  factory ChatStreamEventDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatStreamEventDtoFromJson(json);
}
