import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_answer_block_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_answer_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_content_block_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_message_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_stream_event_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/mappers/chat_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/shop/shop.dart'
    show decodeShopProductRow;
import 'package:tryzeon/feature/personal/wardrobe/wardrobe.dart'
    show decodeWardrobeItemRow;

@AutoMappr([
  MapType<ChatMessage, ChatMessageDto>(
    fields: [Field('content', custom: ChatMapprHelper.contentToDto)],
  ),
  MapType<ChatAnswerDto, ChatMessage>(
    fields: [Field('content', custom: ChatMapprHelper.answerContentToEntity)],
  ),
  MapType<ChatToolUseEventDto, ToolUseBlock>(),
  MapType<ChatToolResultEventDto, ToolResultBlock>(),
])
class ChatMappr extends $ChatMappr {
  const ChatMappr();
}

class ChatMapprHelper {
  static List<ChatContentBlockDto> contentToDto(final ChatMessage source) => [
    for (final block in source.content)
      switch (block) {
        TextBlock(:final text) => ChatContentBlockDto.text(text: text),
        ToolUseBlock(:final id, :final name, :final input) =>
          ChatContentBlockDto.toolUse(id: id, name: name, input: input),
        ToolResultBlock(:final toolUseId, :final content) =>
          ChatContentBlockDto.toolResult(
            toolUseId: toolUseId,
            content: content,
          ),
        ShopProductBlock(:final product) => ChatContentBlockDto.product(
          id: product.id,
        ),
        WardrobeProductBlock(:final item) => ChatContentBlockDto.wardrobe(
          id: item.id,
        ),
      },
  ];

  static List<ContentBlock> answerContentToEntity(final ChatAnswerDto source) =>
      [
        for (final block in source.content)
          ?switch (block) {
            ChatAnswerTextDto(:final text) => ContentBlock.text(text),
            ChatAnswerProductDto(:final item) => ContentBlock.shopProduct(
              decodeShopProductRow(item),
            ),
            ChatAnswerWardrobeDto(:final item) => ContentBlock.wardrobeProduct(
              decodeWardrobeItemRow(item),
            ),
            ChatAnswerUnknownDto() => null,
          },
      ];
}
