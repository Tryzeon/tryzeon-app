import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/tool_step_label.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_notifier.dart';

part 'chat_timeline.freezed.dart';
part 'chat_timeline.g.dart';

enum ChatTurnStatus { thinking, searching, composing, done }

@freezed
sealed class ChatToolStep with _$ChatToolStep {
  const factory ChatToolStep({
    required final ToolUseBlock use,
    final ToolResultBlock? result,
  }) = _ChatToolStep;

  const ChatToolStep._();

  bool get isRunning => result == null;
  int get itemCount => result == null ? 0 : toolStepItemCount(result!);
}

@freezed
sealed class ChatSegment with _$ChatSegment {
  const factory ChatSegment.text(final String text) = ChatTextSegment;
  const factory ChatSegment.cards(final List<ContentBlock> cards) =
      ChatCardSegment;
}

@freezed
sealed class ChatTimelineEntry with _$ChatTimelineEntry {
  const factory ChatTimelineEntry.welcome({required final bool showStarters}) =
      ChatWelcomeEntry;
  const factory ChatTimelineEntry.user(final String text) = ChatUserEntry;
  const factory ChatTimelineEntry.assistant({
    @Default([]) final List<ChatToolStep> steps,
    @Default([]) final List<ChatSegment> segments,
    required final ChatTurnStatus status,
  }) = ChatAssistantEntry;
  const factory ChatTimelineEntry.failure(final Failure failure) =
      ChatFailureEntry;
}

class _OpenTurn {
  final List<ChatToolStep> steps = [];
  final List<ChatSegment> segments = [];

  ChatAssistantEntry toEntry(final ChatTurnStatus status) =>
      ChatAssistantEntry(steps: steps, segments: segments, status: status);

  void addCard(final ContentBlock block) {
    final last = segments.isEmpty ? null : segments.last;
    if (last is ChatCardSegment) {
      segments[segments.length - 1] = ChatCardSegment([...last.cards, block]);
    } else {
      segments.add(ChatCardSegment([block]));
    }
  }

  void attachResult(final ToolResultBlock block) {
    final index = steps.indexWhere(
      (final step) => step.use.id == block.toolUseId,
    );
    if (index == -1) return;
    steps[index] = steps[index].copyWith(result: block);
  }
}

List<ChatTimelineEntry> buildChatTimeline(final ChatState state) {
  final entries = <ChatTimelineEntry>[
    ChatWelcomeEntry(showStarters: state.isPristine && !state.isLoading),
  ];
  _OpenTurn? turn;

  void closeTurn() {
    final closing = turn;
    if (closing == null) return;
    entries.add(closing.toEntry(ChatTurnStatus.done));
    turn = null;
  }

  for (final message in state.messages.skip(1)) {
    var hasNonToolBlock = false;
    for (final block in message.content) {
      switch (block) {
        case TextBlock(:final text) when message.role == ChatRole.user:
          closeTurn();
          entries.add(ChatUserEntry(text));
        case ToolUseBlock():
          (turn ??= _OpenTurn()).steps.add(ChatToolStep(use: block));
        case ToolResultBlock():
          turn?.attachResult(block);
        case TextBlock(:final text):
          hasNonToolBlock = true;
          (turn ??= _OpenTurn()).segments.add(ChatTextSegment(text));
        case ShopProductBlock():
        case WardrobeProductBlock():
          hasNonToolBlock = true;
          (turn ??= _OpenTurn()).addCard(block);
      }
    }
    if (message.role == ChatRole.assistant && hasNonToolBlock) closeTurn();
  }

  final open = turn;
  if (open != null) {
    entries.add(
      open.toEntry(
        state.isLoading ? _liveStatus(open.steps) : ChatTurnStatus.done,
      ),
    );
  } else if (state.isLoading) {
    entries.add(const ChatAssistantEntry(status: ChatTurnStatus.thinking));
  }

  final failure = state.failure;
  if (failure != null) entries.add(ChatFailureEntry(failure));

  return entries;
}

ChatTurnStatus _liveStatus(final List<ChatToolStep> steps) {
  if (steps.isEmpty) return ChatTurnStatus.thinking;
  return steps.last.isRunning
      ? ChatTurnStatus.searching
      : ChatTurnStatus.composing;
}

@riverpod
List<ChatTimelineEntry> chatTimeline(final Ref ref) =>
    buildChatTimeline(ref.watch(chatProvider));
