import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_entrance.dart';

class ChatCardRail extends StatelessWidget {
  const ChatCardRail({
    super.key,
    required this.cards,
    required this.cardWidth,
    required this.padding,
    required this.animate,
    this.delay = Duration.zero,
  });

  final List<Widget> cards;
  final double cardWidth;
  final EdgeInsets padding;
  final bool animate;
  final Duration delay;

  static const double itemWidth = 152;
  static const double outfitWidth = 276;

  @override
  Widget build(final BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, card) in cards.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.smMd),
              ChatEntrance(
                key: ValueKey(index),
                animate: animate,
                delay: delay + AppDuration.quick * index,
                child: SizedBox(width: cardWidth, child: card),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
