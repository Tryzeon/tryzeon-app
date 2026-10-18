import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_items.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/tool_step_label.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_notifier.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

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
  const factory ChatSegment.picks(final List<ResolvedPick> picks) =
      ChatPicksSegment;
  const factory ChatSegment.outfits(final List<ResolvedOutfit> outfits) =
      ChatOutfitsSegment;
}

@freezed
sealed class ResolvedOutfit with _$ResolvedOutfit {
  const factory ResolvedOutfit({
    required final String title,
    final String? reason,
    required final List<ResolvedItem> pieces,
  }) = _ResolvedOutfit;
}

@freezed
sealed class ResolvedPick with _$ResolvedPick {
  const factory ResolvedPick({
    required final ResolvedItem item,
    final String? highlight,
  }) = _ResolvedPick;
}

@freezed
sealed class ResolvedItem with _$ResolvedItem {
  const factory ResolvedItem.product(final ShopProduct product) =
      ResolvedProduct;
  const factory ResolvedItem.wardrobe(final WardrobeItem item) =
      ResolvedWardrobeItem;
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

  void attachResult(final ToolResultBlock block) {
    final index = steps.indexWhere(
      (final step) => step.use.id == block.toolUseId,
    );
    if (index == -1) return;
    steps[index] = steps[index].copyWith(result: block);
  }
}

ResolvedItem? _resolve(final ItemRef ref, final ChatItems items) =>
    switch (ref) {
      ProductItemRef(:final id) => switch (items.products[id]) {
        final product? => ResolvedItem.product(product),
        null => null,
      },
      WardrobeItemRef(:final id) => switch (items.wardrobe[id]) {
        final wardrobeItem? => ResolvedItem.wardrobe(wardrobeItem),
        null => null,
      },
    };

const _emptyAnswerText = '抱歉，我沒有理解，可以再說一次你的需求嗎？';

ResolvedOutfit? _resolveOutfit(final ChatOutfit outfit, final ChatItems items) {
  final pieces = [for (final ref in outfit.pieces) _resolve(ref, items)];
  if (pieces.contains(null)) return null;
  return ResolvedOutfit(
    title: outfit.title,
    reason: outfit.reason,
    pieces: pieces.nonNulls.toList(),
  );
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
    var addedSegment = false;
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
          addedSegment = true;
          (turn ??= _OpenTurn()).segments.add(ChatTextSegment(text));
        case PicksBlock(:final picks):
          hasNonToolBlock = true;
          final resolved = [
            for (final pick in picks)
              if (_resolve(pick.ref, state.items) case final item?)
                ResolvedPick(item: item, highlight: pick.highlight),
          ];
          if (resolved.isNotEmpty) {
            addedSegment = true;
            (turn ??= _OpenTurn()).segments.add(ChatPicksSegment(resolved));
          }
        case OutfitsBlock(:final outfits):
          hasNonToolBlock = true;
          final looks = [
            for (final outfit in outfits) ?_resolveOutfit(outfit, state.items),
          ];
          if (looks.isNotEmpty) {
            addedSegment = true;
            (turn ??= _OpenTurn()).segments.add(ChatOutfitsSegment(looks));
          }
      }
    }
    final isFinalAnswer =
        message.role == ChatRole.assistant &&
        !message.content.any((final block) => block is ToolUseBlock);
    if (isFinalAnswer && !addedSegment) {
      (turn ??= _OpenTurn()).segments.add(
        const ChatTextSegment(_emptyAnswerText),
      );
    }
    if (message.role == ChatRole.assistant &&
        (hasNonToolBlock || isFinalAnswer)) {
      closeTurn();
    }
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
