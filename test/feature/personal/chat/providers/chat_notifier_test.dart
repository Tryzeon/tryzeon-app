import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_items.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_event.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_notifier.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_providers.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

class _FakeChatAction extends ChatAction {
  _FakeChatAction(this.turns, this.histories);

  final List<List<ChatStreamEvent>> turns;
  final List<List<ChatMessage>> histories;

  @override
  Stream<ChatStreamEvent> execute(final List<ChatMessage> history) {
    histories.add(history);
    return Stream.fromIterable(turns.removeAt(0));
  }
}

const _toolStarted = ChatStreamEvent.toolStarted(
  ToolUseBlock(id: 't1', name: 'search_products'),
);
const _toolFinished = ChatStreamEvent.toolFinished(
  ToolResultBlock(toolUseId: 't1'),
);
WardrobeItem _wardrobeItem(final String id) => WardrobeItem(
  id: id,
  imagePath: '$id.jpg',
  garmentType: GarmentType.top,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

const _answer = ChatMessage(
  role: ChatRole.assistant,
  content: [ContentBlock.text('這套很適合你')],
);

({ProviderContainer container, List<List<ChatMessage>> histories}) _setUp(
  final List<List<ChatStreamEvent>> turns,
) {
  final histories = <List<ChatMessage>>[];
  final container = ProviderContainer(
    retry: (final _, final _) => null,
    overrides: [
      chatActionProvider.overrideWith(() => _FakeChatAction(turns, histories)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(chatProvider, (final _, final _) {});
  return (container: container, histories: histories);
}

void main() {
  test('a failed turn rolls back its steps and records the failure', () async {
    final (:container, histories: _) = _setUp([
      [
        _toolStarted,
        _toolFinished,
        const ChatStreamEvent.failed(ServerFailure()),
      ],
    ]);

    await container.read(chatProvider.notifier).sendMessage('找白襯衫');

    final state = container.read(chatProvider);
    expect(state.messages, hasLength(2));
    expect(state.messages.last.role, ChatRole.user);
    expect(state.failure, isA<ServerFailure>());
    expect(state.isLoading, isFalse);
  });

  test('retry clears the failure and replays the same history', () async {
    final (:container, :histories) = _setUp([
      [
        _toolStarted,
        _toolFinished,
        const ChatStreamEvent.failed(ServerFailure()),
      ],
      [
        const ChatStreamEvent.replied(messages: [_answer], items: ChatItems()),
      ],
    ]);
    final notifier = container.read(chatProvider.notifier);

    await notifier.sendMessage('找白襯衫');
    await notifier.retry();

    final state = container.read(chatProvider);
    expect(state.failure, isNull);
    expect(histories, hasLength(2));
    expect(histories[1], histories[0]);
    expect(state.messages.last, _answer);
  });

  test(
    'an answer replaces the streamed steps with the turn the server recorded',
    () async {
      const recorded = [
        ChatMessage(
          role: ChatRole.assistant,
          content: [
            ToolUseBlock(id: 't1', name: 'search_products'),
            ToolUseBlock(id: 't2', name: 'search_wardrobe'),
          ],
        ),
        ChatMessage(
          role: ChatRole.user,
          content: [
            ToolResultBlock(toolUseId: 't1'),
            ToolResultBlock(toolUseId: 't2'),
          ],
        ),
        _answer,
      ];
      final (:container, histories: _) = _setUp([
        [
          _toolStarted,
          const ChatStreamEvent.toolStarted(
            ToolUseBlock(id: 't2', name: 'search_wardrobe'),
          ),
          _toolFinished,
          const ChatStreamEvent.toolFinished(ToolResultBlock(toolUseId: 't2')),
          const ChatStreamEvent.replied(messages: recorded, items: ChatItems()),
        ],
      ]);

      await container.read(chatProvider.notifier).sendMessage('找白襯衫');

      expect(container.read(chatProvider).messages.skip(1), const [
        ChatMessage(role: ChatRole.user, content: [TextBlock('找白襯衫')]),
        ...recorded,
      ]);
    },
  );

  test(
    'items from earlier answers stay renderable after a later one',
    () async {
      final w1 = _wardrobeItem('w1');
      final w2 = _wardrobeItem('w2');
      final (:container, histories: _) = _setUp([
        [
          ChatStreamEvent.replied(
            messages: const [_answer],
            items: ChatItems(wardrobe: {'w1': w1}),
          ),
        ],
        [
          ChatStreamEvent.replied(
            messages: const [_answer],
            items: ChatItems(wardrobe: {'w2': w2}),
          ),
        ],
      ]);
      final notifier = container.read(chatProvider.notifier);

      await notifier.sendMessage('找上衣');
      await notifier.sendMessage('再一件');

      expect(container.read(chatProvider).items.wardrobe, {'w1': w1, 'w2': w2});
    },
  );

  test('a stream without a terminal event fails with ServerFailure', () async {
    final (:container, histories: _) = _setUp([[]]);

    await container.read(chatProvider.notifier).sendMessage('找白襯衫');

    expect(container.read(chatProvider).failure, isA<ServerFailure>());
  });

  test('a rate-limit failure emits rateLimited', () async {
    final (:container, histories: _) = _setUp([
      [const ChatStreamEvent.failed(RateLimitFailure())],
    ]);
    final notifier = container.read(chatProvider.notifier);

    final emitted = expectLater(notifier.events, emits(isA<ChatRateLimited>()));
    await notifier.sendMessage('找白襯衫');
    await emitted;

    expect(container.read(chatProvider).failure, isA<RateLimitFailure>());
  });
}
