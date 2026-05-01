import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatThinkingBubble extends StatefulWidget {
  const ChatThinkingBubble({super.key});

  @override
  State<ChatThinkingBubble> createState() => _ChatThinkingBubbleState();
}

class _ChatThinkingBubbleState extends State<ChatThinkingBubble>
    with SingleTickerProviderStateMixin {
  static const _dotFrames = ['', '.', '..', '...', '..', '.'];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDuration.thinking)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final _) {
            final frameIndex =
                (_controller.value * _dotFrames.length).floor() % _dotFrames.length;

            return Text('Thinking${_dotFrames[frameIndex]}', style: textStyle);
          },
        ),
      ),
    );
  }
}
