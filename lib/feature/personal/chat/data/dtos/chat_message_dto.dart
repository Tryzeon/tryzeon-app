import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_content_block_dto.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';

part 'chat_message_dto.g.dart';

@JsonSerializable(explicitToJson: true, checked: true)
class ChatMessageDto {
  const ChatMessageDto({required this.role, required this.content});

  factory ChatMessageDto.fromJson(final Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  final ChatRole role;
  final List<ChatContentBlockDto> content;

  Map<String, dynamic> toJson() => _$ChatMessageDtoToJson(this);
}
