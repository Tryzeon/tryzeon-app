import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_assistant_turn.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_entrance.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_failure_card.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_user_bubble.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_welcome.dart';

class ChatTimelineList extends HookWidget {
  const ChatTimelineList({
    super.key,
    required this.entries,
    required this.controller,
    required this.onStarterTap,
    required this.onRetry,
    required this.onUpgrade,
  });

  final List<ChatTimelineEntry> entries;
  final ScrollController controller;
  final ValueChanged<String> onStarterTap;
  final VoidCallback onRetry;
  final VoidCallback onUpgrade;

  static const double jumpThreshold = 240;
  static const EdgeInsets _padding = EdgeInsets.only(
    top: AppSpacing.sm,
    bottom: AppSpacing.md,
  );
  static const EdgeInsets _gutter = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
  );

  @override
  Widget build(final BuildContext context) {
    // Lazily built items are rebuilt when scrolled back into view; remembering
    // which indices already entered keeps the entrance from replaying.
    final entered = useRef<Set<int>?>(null);
    final seen = entered.value ??= {for (var i = 0; i < entries.length; i++) i};
    seen.removeWhere((final index) => index >= entries.length);

    return LayoutBuilder(
      builder: (final context, final constraints) => ListView.separated(
        reverse: true,
        controller: controller,
        padding: _padding,
        itemCount: entries.length,
        findItemIndexCallback: (final key) {
          if (key is! ValueKey<int> || key.value >= entries.length) return null;
          return entries.length - 1 - key.value;
        },
        separatorBuilder: (final _, final _) =>
            const SizedBox(height: AppSpacing.lg),
        itemBuilder: (final context, final reversedIndex) {
          final index = entries.length - 1 - reversedIndex;
          return ChatEntrance(
            key: ValueKey(index),
            animate: seen.add(index),
            child: switch (entries[index]) {
              ChatWelcomeEntry(:final showStarters) => Padding(
                padding: _gutter,
                child: ChatWelcome(
                  showStarters: showStarters,
                  minHeight: constraints.maxHeight - _padding.vertical,
                  onPromptTap: onStarterTap,
                ),
              ),
              ChatUserEntry(:final text) => Padding(
                padding: _gutter,
                child: ChatUserBubble(text: text),
              ),
              final ChatAssistantEntry entry => ChatAssistantTurn(
                entry: entry,
                gutter: _gutter,
              ),
              ChatFailureEntry(:final failure) => Padding(
                padding: _gutter,
                child: ChatFailureCard(
                  failure: failure,
                  onRetry: onRetry,
                  onUpgrade: onUpgrade,
                ),
              ),
            },
          );
        },
      ),
    );
  }
}
