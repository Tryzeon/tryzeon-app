import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_content_block_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_items_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_message_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_recommended_item_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_stream_event_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/mappers/chat_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_items.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/shop.dart'
    show decodeShopProductRow;
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/wardrobe.dart'
    show decodeWardrobeItemRow;

@AutoMappr([
  MapType<ChatMessage, ChatMessageDto>(
    fields: [Field('content', custom: ChatMapprHelper.contentToDto)],
  ),
  MapType<ChatMessageDto, ChatMessage>(
    fields: [Field('content', custom: ChatMapprHelper.contentToEntity)],
  ),
  MapType<ChatItemsDto, ChatItems>(
    fields: [
      Field('products', custom: ChatMapprHelper.productsToEntity),
      Field('wardrobe', custom: ChatMapprHelper.wardrobeToEntity),
    ],
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
        RecommendationBlock(:final items) => ChatContentBlockDto.recommendation(
          items: [
            for (final item in items)
              switch (item) {
                RecommendedProduct(:final id) => ChatRecommendedItemDto.product(
                  id: id,
                ),
                RecommendedWardrobeItem(:final id) =>
                  ChatRecommendedItemDto.wardrobe(id: id),
              },
          ],
        ),
      },
  ];

  static List<ContentBlock> contentToEntity(final ChatMessageDto source) => [
    for (final block in source.content)
      ?switch (block) {
        ChatTextBlockDto(:final text) => ContentBlock.text(text),
        ChatToolUseBlockDto(:final id, :final name, :final input) =>
          ContentBlock.toolUse(id: id, name: name, input: input),
        ChatToolResultBlockDto(:final toolUseId, :final content) =>
          ContentBlock.toolResult(toolUseId: toolUseId, content: content),
        ChatRecommendationBlockDto(:final items) =>
          ContentBlock.recommendation([
            for (final item in items)
              ?switch (item) {
                ChatRecommendedProductDto(:final id) => RecommendedItem.product(
                  id,
                ),
                ChatRecommendedWardrobeDto(:final id) =>
                  RecommendedItem.wardrobe(id),
                ChatRecommendedUnknownDto() => null,
              },
          ]),
        ChatUnknownBlockDto() => null,
      },
  ];

  static Map<String, ShopProduct> productsToEntity(final ChatItemsDto source) =>
      source.products.map(
        (final id, final row) => MapEntry(id, decodeShopProductRow(row)),
      );

  static Map<String, WardrobeItem> wardrobeToEntity(
    final ChatItemsDto source,
  ) => source.wardrobe.map(
    (final id, final row) => MapEntry(id, decodeWardrobeItemRow(row)),
  );
}
