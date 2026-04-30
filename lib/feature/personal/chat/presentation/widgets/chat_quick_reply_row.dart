import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatQuickReplyRow extends StatelessWidget {
  const ChatQuickReplyRow({super.key, required this.replies, required this.onReply});

  final List<String> replies;
  final ValueChanged<String> onReply;

  @override
  Widget build(final BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: AppSpacing.xxl + AppSpacing.sm,
      child: Stack(
        children: [
          ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            itemCount: replies.length,
            itemBuilder: (final context, final index) {
              final reply = replies[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: ActionChip(label: Text(reply), onPressed: () => onReply(reply)),
              );
            },
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: AppSpacing.xl, // 32px
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
