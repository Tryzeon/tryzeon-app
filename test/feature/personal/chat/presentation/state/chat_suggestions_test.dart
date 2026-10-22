import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_suggestions.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_notifier.dart';

const _greeting = ChatMessage(
  role: ChatRole.assistant,
  content: [ContentBlock.text('hi')],
);

const _question = ChatMessage(
  role: ChatRole.user,
  content: [ContentBlock.text('找衣服')],
);

const _answered = ChatState(
  messages: [
    _greeting,
    _question,
    ChatMessage(
      role: ChatRole.assistant,
      content: [ContentBlock.text('要單品還是整套？')],
    ),
  ],
  suggestions: ['單品', '整套'],
);

class _Fixed extends ChatNotifier {
  _Fixed(this.fixed);

  final ChatState fixed;

  @override
  ChatState build() {
    super.build();
    return fixed;
  }
}

List<String> _suggestionsFor(final ChatState state) {
  final container = ProviderContainer(
    overrides: [chatProvider.overrideWith(() => _Fixed(state))],
  );
  addTearDown(container.dispose);
  return container.read(chatSuggestionsProvider);
}

void main() {
  test('offers the latest answer\'s suggestions', () {
    expect(_suggestionsFor(_answered), ['單品', '整套']);
  });

  test('offers nothing while a turn is running', () {
    expect(_suggestionsFor(_answered.copyWith(isLoading: true)), isEmpty);
  });

  test('offers nothing under an answer that rendered nothing of its own', () {
    const state = ChatState(
      messages: [
        _greeting,
        _question,
        ChatMessage(
          role: ChatRole.assistant,
          content: [
            ContentBlock.picks([ChatPick(ref: ItemRef.product('gone'))]),
          ],
        ),
      ],
      suggestions: ['便宜一點的'],
    );

    expect(_suggestionsFor(state), isEmpty);
  });

  test('offers nothing when the answer brought none', () {
    expect(_suggestionsFor(_answered.copyWith(suggestions: [])), isEmpty);
  });
}
