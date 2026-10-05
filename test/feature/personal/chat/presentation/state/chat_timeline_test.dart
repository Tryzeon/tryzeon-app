import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_notifier.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

const _greeting = ChatMessage(
  role: ChatRole.assistant,
  content: [ContentBlock.text('hi')],
);

ChatMessage _user(final List<ContentBlock> content) =>
    ChatMessage(role: ChatRole.user, content: content);

ChatMessage _assistant(final List<ContentBlock> content) =>
    ChatMessage(role: ChatRole.assistant, content: content);

ShopProduct _product(final String id) => ShopProduct(
  storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
  name: 'Tee',
  categoryId: 'c',
  garmentType: GarmentType.top,
  price: 690,
  imagePaths: const ['p.jpg'],
  imageUrls: const ['https://x/p.jpg'],
  id: id,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

WardrobeItem _wardrobe(final String id) => WardrobeItem(
  id: id,
  imagePath: 'w.jpg',
  garmentType: GarmentType.top,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

const _toolUse = ContentBlock.toolUse(id: 't1', name: 'search_products');
const _toolResult = ContentBlock.toolResult(
  toolUseId: 't1',
  content: {
    'items': [1, 2, 3],
  },
);

void main() {
  test('a pristine conversation is only the welcome entry with starters', () {
    final entries = buildChatTimeline(const ChatState(messages: [_greeting]));

    expect(entries, [const ChatWelcomeEntry(showStarters: true)]);
  });

  test('groups a finished turn into steps and segments', () {
    final entries = buildChatTimeline(
      ChatState(
        messages: [
          _greeting,
          _user([const ContentBlock.text('找白襯衫')]),
          _assistant([_toolUse]),
          _user([_toolResult]),
          _assistant([
            const ContentBlock.text('a'),
            ContentBlock.shopProduct(_product('p1')),
            ContentBlock.shopProduct(_product('p2')),
            const ContentBlock.text('b'),
            ContentBlock.wardrobeProduct(_wardrobe('w1')),
          ]),
        ],
      ),
    );

    expect(entries, hasLength(3));
    expect(entries[0], const ChatWelcomeEntry(showStarters: false));
    expect(entries[1], const ChatUserEntry('找白襯衫'));

    final turn = entries[2] as ChatAssistantEntry;
    expect(turn.status, ChatTurnStatus.done);
    expect(turn.steps, hasLength(1));
    expect(turn.steps.single.itemCount, 3);
    expect(turn.segments, hasLength(4));
    expect(turn.segments[0], const ChatTextSegment('a'));
    expect((turn.segments[1] as ChatCardSegment).cards, hasLength(2));
    expect(turn.segments[2], const ChatTextSegment('b'));
    expect((turn.segments[3] as ChatCardSegment).cards, hasLength(1));
  });

  group('live turn status', () {
    final userAsk = _user([const ContentBlock.text('找白襯衫')]);

    test('thinking before any step arrives', () {
      final entries = buildChatTimeline(
        ChatState(messages: [_greeting, userAsk], isLoading: true),
      );

      expect(
        entries.last,
        const ChatAssistantEntry(status: ChatTurnStatus.thinking),
      );
    });

    test('searching while the last step has no result', () {
      final entries = buildChatTimeline(
        ChatState(
          messages: [
            _greeting,
            userAsk,
            _assistant([_toolUse]),
          ],
          isLoading: true,
        ),
      );

      expect(
        (entries.last as ChatAssistantEntry).status,
        ChatTurnStatus.searching,
      );
    });

    test('composing once every step has a result', () {
      final entries = buildChatTimeline(
        ChatState(
          messages: [
            _greeting,
            userAsk,
            _assistant([_toolUse]),
            _user([_toolResult]),
          ],
          isLoading: true,
        ),
      );

      expect(
        (entries.last as ChatAssistantEntry).status,
        ChatTurnStatus.composing,
      );
    });
  });

  test('a failure is the last entry', () {
    final entries = buildChatTimeline(
      ChatState(
        messages: [
          _greeting,
          _user([const ContentBlock.text('找白襯衫')]),
        ],
        failure: const ServiceBusyFailure(),
      ),
    );

    expect(entries.last, const ChatFailureEntry(ServiceBusyFailure()));
  });
}
