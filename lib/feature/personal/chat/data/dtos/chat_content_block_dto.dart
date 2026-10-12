import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_content_block_dto.freezed.dart';
part 'chat_content_block_dto.g.dart';

/// Products and wardrobe items are sent by id only — their full data is
/// already replayed in the paired tool_result, so the model needs just the
/// reference.
@Freezed(
  unionKey: 'type',
  unionValueCase: FreezedUnionCase.snake,
  fromJson: false,
  toJson: true,
)
sealed class ChatContentBlockDto with _$ChatContentBlockDto {
  const factory ChatContentBlockDto.text({required final String text}) =
      ChatTextBlockDto;

  const factory ChatContentBlockDto.toolUse({
    required final String id,
    required final String name,
    required final Map<String, dynamic> input,
  }) = ChatToolUseBlockDto;

  const factory ChatContentBlockDto.toolResult({
    @JsonKey(name: 'tool_use_id') required final String toolUseId,
    required final Map<String, dynamic> content,
  }) = ChatToolResultBlockDto;

  const factory ChatContentBlockDto.product({required final String id}) =
      ChatProductBlockDto;

  const factory ChatContentBlockDto.wardrobe({required final String id}) =
      ChatWardrobeBlockDto;
}
