import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/domain/usecases/send_chat_message.dart';
import 'package:tryzeon/feature/personal/chat/presentation/pages/chat_page.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_jump_to_latest_button.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_suggestion_bar.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_user_bubble.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_notifier.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_providers.dart';

class _LongChat extends ChatNotifier {
  @override
  ChatState build() {
    super.build();
    return ChatState(
      messages: [
        for (var i = 0; i < 30; i++)
          ChatMessage(
            role: ChatRole.user,
            content: [ContentBlock.text('message $i')],
          ),
      ],
    );
  }
}

class _AskedChat extends ChatNotifier {
  @override
  ChatState build() {
    super.build();
    return const ChatState(
      messages: [
        ChatMessage(
          role: ChatRole.assistant,
          content: [ContentBlock.text('hi')],
        ),
        ChatMessage(role: ChatRole.user, content: [ContentBlock.text('找衣服')]),
        ChatMessage(
          role: ChatRole.assistant,
          content: [ContentBlock.text('要單品還是整套？')],
        ),
      ],
      suggestions: ['單品', '整套'],
    );
  }
}

class _PendingSend implements SendChatMessage {
  _PendingSend(this.pending);

  final Stream<ChatStreamEvent> pending;

  @override
  Stream<ChatStreamEvent> call(final List<ChatMessage> history) => pending;
}

void main() {
  bool jumpVisible(final WidgetTester tester) => tester
      .widget<ChatJumpToLatestButton>(find.byType(ChatJumpToLatestButton))
      .visible;

  testWidgets('the jump button hides once a reset leaves nothing to scroll', (
    final tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatProvider.overrideWith(_LongChat.new)],
        child: const MaterialApp(home: ChatPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(jumpVisible(tester), isTrue);

    ProviderScope.containerOf(
      tester.element(find.byType(ChatPage)),
    ).read(chatProvider.notifier).reset();
    await tester.pumpAndSettle();

    expect(jumpVisible(tester), isFalse);
  });

  testWidgets('tapping a suggestion sends it and the chips go away', (
    final tester,
  ) async {
    final pending = StreamController<ChatStreamEvent>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatProvider.overrideWith(_AskedChat.new),
          sendChatMessageUseCaseProvider.overrideWithValue(
            _PendingSend(pending.stream),
          ),
        ],
        child: const MaterialApp(home: ChatPage()),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(ChatSuggestionBar),
        matching: find.text('單品'),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.descendant(
        of: find.byType(ChatUserBubble),
        matching: find.text('單品'),
      ),
      findsOneWidget,
    );
    expect(find.byType(ActionChip), findsNothing);

    await pending.close();
    await tester.pump(const Duration(seconds: 1));
  });
}
