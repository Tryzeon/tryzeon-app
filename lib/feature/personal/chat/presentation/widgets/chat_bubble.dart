import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';

class ChatBubble extends HookWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;

    final styleSheet = useMemoized(
      () => MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: isUser
            ? theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary)
            : theme.textTheme.bodyLarge,
      ),
      [theme, isUser],
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : colorScheme.surfaceContainerLowest,
          border: isUser ? null : Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.card),
            topRight: const Radius.circular(AppRadius.card),
            bottomLeft: Radius.circular(isUser ? AppRadius.card : 0),
            bottomRight: Radius.circular(isUser ? 0 : AppRadius.card),
          ),
        ),
        child: MarkdownBody(data: message.text, selectable: true, styleSheet: styleSheet),
      ),
    );
  }
}
