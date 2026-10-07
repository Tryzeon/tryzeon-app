import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/presentation/pages/chat_page.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_jump_to_latest_button.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_notifier.dart';

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
}
