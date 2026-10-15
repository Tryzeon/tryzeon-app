import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_entrance.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_product_card.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_wardrobe_card.dart';

class ChatCardRail extends StatelessWidget {
  const ChatCardRail({
    super.key,
    required this.cards,
    required this.padding,
    required this.animate,
    this.delay = Duration.zero,
  });

  final List<ChatRecommendation> cards;
  final EdgeInsets padding;
  final bool animate;
  final Duration delay;

  static const double cardWidth = 150;

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
                child: SizedBox(
                  width: cardWidth,
                  child: switch (card) {
                    ChatProductRecommendation(:final product) =>
                      ChatProductCard(product: product),
                    ChatWardrobeRecommendation(:final item) => ChatWardrobeCard(
                      item: item,
                    ),
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
