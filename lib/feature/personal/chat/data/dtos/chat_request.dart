import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_message_dto.dart';

part 'chat_request.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class ChatRequest {
  const ChatRequest({required this.messages});

  final List<ChatMessageDto> messages;

  Map<String, dynamic> toJson() => _$ChatRequestToJson(this);
}
