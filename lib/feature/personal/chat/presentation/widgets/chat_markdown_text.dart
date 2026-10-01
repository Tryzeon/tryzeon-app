import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatMarkdownText extends HookWidget {
  const ChatMarkdownText({super.key, required this.text});

  final String text;

  static const double lineHeight = 1.5;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    final styleSheet = useMemoized(() {
      final body = theme.textTheme.bodyLarge?.copyWith(
        height: lineHeight,
        color: theme.colorScheme.onSurface,
      );
      final heading = theme.textTheme.titleMedium;
      return MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: body,
        listBullet: body,
        strong: const TextStyle(fontWeight: FontWeight.w600),
        h1: heading,
        h2: heading,
        h3: heading,
        blockSpacing: AppSpacing.sm,
        listIndent: AppSpacing.md,
      );
    }, [theme]);

    return MarkdownBody(data: text, styleSheet: styleSheet);
  }
}
