import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_answer_block_dto.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';

part 'chat_answer_dto.g.dart';

@JsonSerializable(createToJson: false, checked: true)
class ChatAnswerDto {
  const ChatAnswerDto({required this.role, required this.content});

  factory ChatAnswerDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatAnswerDtoFromJson(json);

  final ChatRole role;
  final List<ChatAnswerBlockDto> content;
}
