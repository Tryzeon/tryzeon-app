import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatJumpToLatestButton extends StatelessWidget {
  const ChatJumpToLatestButton({
    super.key,
    required this.visible,
    required this.onTap,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppDuration.standard,
      child: IgnorePointer(
        ignoring: !visible,
        child: IconButton.outlined(
          onPressed: onTap,
          style: IconButton.styleFrom(backgroundColor: colorScheme.surface),
          tooltip: '回到最新',
          icon: const Icon(Icons.arrow_downward_rounded, size: AppSpacing.mdLg),
        ),
      ),
    );
  }
}
