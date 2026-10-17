import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_rail.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_entrance.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_markdown_text.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_outfit_card.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_pending_indicator.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_product_card.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_step_rail.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_wardrobe_card.dart';

class ChatAssistantTurn extends HookWidget {
  const ChatAssistantTurn({
    super.key,
    required this.entry,
    required this.gutter,
  });

  final ChatAssistantEntry entry;
  final EdgeInsets gutter;

  static String? _pendingLabel(final ChatTurnStatus status) => switch (status) {
    ChatTurnStatus.thinking => '正在思考',
    ChatTurnStatus.searching => '正在搜尋',
    ChatTurnStatus.composing => '正在整理穿搭建議',
    ChatTurnStatus.done => null,
  };

  @override
  Widget build(final BuildContext context) {
    final pendingLabel = _pendingLabel(entry.status);

    // The reply's text and cards land together when the turn finishes, so
    // "new" means segments this mounted turn has not rendered yet; a turn
    // remounted by scrolling back has no previous count and stays still.
    final renderedSegments = usePrevious(entry.segments.length);
    final firstNewSegment = renderedSegments ?? entry.segments.length;

    return AnimatedSize(
      duration: AppDuration.standard,
      curve: AppCurves.enter,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entry.steps.isNotEmpty)
            Padding(
              key: const ValueKey('steps'),
              padding: gutter,
              child: ChatStepRail(
                steps: entry.steps,
                isLive: pendingLabel != null,
              ),
            ),
          for (final (index, segment) in entry.segments.indexed)
            _spaced(
              key: ValueKey(('segment', index)),
              isFirst: index == 0 && entry.steps.isEmpty,
              child: switch (segment) {
                ChatTextSegment(:final text) => ChatEntrance(
                  animate: index >= firstNewSegment,
                  delay:
                      AppDuration.quick *
                      (index - firstNewSegment).clamp(0, index),
                  child: Padding(
                    padding: gutter,
                    child: ChatMarkdownText(text: text),
                  ),
                ),
                ChatPicksSegment(:final picks) => ChatCardRail(
                  cardWidth: ChatCardRail.itemWidth,
                  cards: [
                    for (final pick in picks)
                      switch (pick.item) {
                        ResolvedProduct(:final product) => ChatProductCard(
                          product: product,
                          highlight: pick.highlight,
                        ),
                        ResolvedWardrobeItem(item: final wardrobeItem) =>
                          ChatWardrobeCard(
                            item: wardrobeItem,
                            highlight: pick.highlight,
                          ),
                      },
                  ],
                  padding: gutter,
                  animate: index >= firstNewSegment,
                  delay:
                      AppDuration.quick *
                      (index - firstNewSegment).clamp(0, index),
                ),
                ChatOutfitsSegment(:final outfits) => ChatCardRail(
                  cardWidth: ChatCardRail.outfitWidth,
                  cards: [
                    for (final outfit in outfits)
                      ChatOutfitCard(outfit: outfit),
                  ],
                  padding: gutter,
                  animate: index >= firstNewSegment,
                  delay:
                      AppDuration.quick *
                      (index - firstNewSegment).clamp(0, index),
                ),
              },
            ),
          if (pendingLabel != null)
            _spaced(
              key: const ValueKey('pending'),
              isFirst: entry.steps.isEmpty && entry.segments.isEmpty,
              child: Padding(
                padding: gutter,
                child: ChatPendingIndicator(label: pendingLabel),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _spaced({
    required final Key key,
    required final bool isFirst,
    required final Widget child,
  }) => Padding(
    key: key,
    padding: EdgeInsets.only(top: isFirst ? 0 : AppSpacing.smMd),
    child: child,
  );
}
