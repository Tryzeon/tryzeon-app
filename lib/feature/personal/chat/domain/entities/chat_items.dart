import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

part 'chat_items.freezed.dart';

/// What the answers' item ids render as, keyed by id. Never part of the
/// transcript: a reply's items are merged in, the messages only name them.
@freezed
sealed class ChatItems with _$ChatItems {
  const factory ChatItems({
    @Default({}) final Map<String, ShopProduct> products,
    @Default({}) final Map<String, WardrobeItem> wardrobe,
  }) = _ChatItems;

  const ChatItems._();

  ChatItems merge(final ChatItems other) => ChatItems(
    products: {...products, ...other.products},
    wardrobe: {...wardrobe, ...other.wardrobe},
  );
}
