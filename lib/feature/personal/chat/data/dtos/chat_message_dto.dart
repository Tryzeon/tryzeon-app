import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_content_block_dto.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';

part 'chat_message_dto.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class ChatMessageDto {
  const ChatMessageDto({required this.role, required this.content});

  final ChatRole role;
  final List<ChatContentBlockDto> content;

  Map<String, dynamic> toJson() => _$ChatMessageDtoToJson(this);
}
