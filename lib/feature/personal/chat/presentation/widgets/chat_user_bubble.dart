import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_markdown_text.dart';

class ChatUserBubble extends StatelessWidget {
  const ChatUserBubble({super.key, required this.text});

  final String text;

  static const double _maxWidthFactor = 0.8;
  static const BorderRadius _radius = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.card),
    topRight: Radius.circular(AppRadius.card),
    bottomLeft: Radius.circular(AppRadius.card),
    bottomRight: Radius.circular(AppSpacing.xs),
  );

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.smMd,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: _radius,
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            height: ChatMarkdownText.lineHeight,
          ),
        ),
      ),
    );
  }
}
