import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_content_block_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_item_ref_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_items_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_message_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_outfit_dto.dart';
import 'package:tryzeon/feature/personal/chat/data/dtos/chat_pick_dto.dart';
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
        PicksBlock(:final picks) => ChatContentBlockDto.picks(
          picks: [for (final pick in picks) _pickToDto(pick)],
        ),
        OutfitsBlock(:final outfits) => ChatContentBlockDto.outfits(
          outfits: [
            for (final outfit in outfits)
              ChatOutfitDto(
                title: outfit.title,
                reason: outfit.reason,
                pieces: [for (final piece in outfit.pieces) _refToDto(piece)],
              ),
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
        ChatPicksBlockDto(:final picks) => ContentBlock.picks([
          for (final pick in picks) ?_pickToEntity(pick),
        ]),
        ChatOutfitsBlockDto(:final outfits) => _outfitsToEntity(outfits),
        ChatUnknownBlockDto() => null,
      },
  ];

  static ChatPickDto _pickToDto(final ChatPick pick) => switch (pick.ref) {
    ProductItemRef(:final id, :final colorId) => ChatPickDto.product(
      id: id,
      highlight: pick.highlight,
      colorId: colorId,
    ),
    WardrobeItemRef(:final id) => ChatPickDto.wardrobe(
      id: id,
      highlight: pick.highlight,
    ),
  };

  static ChatPick? _pickToEntity(final ChatPickDto pick) => switch (pick) {
    ChatProductPickDto(:final id, :final highlight, :final colorId) => ChatPick(
      ref: ItemRef.product(id, colorId: colorId),
      highlight: _nonBlank(highlight),
    ),
    ChatWardrobePickDto(:final id, :final highlight) => ChatPick(
      ref: ItemRef.wardrobe(id),
      highlight: _nonBlank(highlight),
    ),
    ChatUnknownPickDto() => null,
  };

  static ChatItemRefDto _refToDto(final ItemRef ref) => switch (ref) {
    ProductItemRef(:final id, :final colorId) => ChatItemRefDto.product(
      id: id,
      colorId: colorId,
    ),
    WardrobeItemRef(:final id) => ChatItemRefDto.wardrobe(id: id),
  };

  static ItemRef? _refToEntity(final ChatItemRefDto ref) => switch (ref) {
    ChatProductRefDto(:final id, :final colorId) => ItemRef.product(
      id,
      colorId: colorId,
    ),
    ChatWardrobeRefDto(:final id) => ItemRef.wardrobe(id),
    ChatUnknownRefDto() => null,
  };

  static String? _nonBlank(final String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static ContentBlock? _outfitsToEntity(final List<ChatOutfitDto> outfits) {
    final kept = [for (final outfit in outfits) ?_outfitToEntity(outfit)];
    return kept.isEmpty ? null : ContentBlock.outfits(kept);
  }

  static ChatOutfit? _outfitToEntity(final ChatOutfitDto outfit) {
    final pieces = [for (final piece in outfit.pieces) _refToEntity(piece)];
    final title = _nonBlank(outfit.title);
    if (title == null || pieces.isEmpty || pieces.contains(null)) return null;
    return ChatOutfit(
      title: title,
      reason: _nonBlank(outfit.reason),
      pieces: pieces.nonNulls.toList(),
    );
  }

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
