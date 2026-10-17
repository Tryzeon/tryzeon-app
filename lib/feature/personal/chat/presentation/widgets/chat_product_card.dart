import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_frame.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/product_outfit_actions.dart';

class ChatProductCard extends ConsumerWidget {
  const ChatProductCard({super.key, required this.product, this.highlight});

  final ShopProduct product;
  final String? highlight;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final label = highlight;

    return ChatCardFrame(
      image: ChatProductImage(product: product),
      tag: label == null ? null : ChatImageTag(label),
      onTap: () => context.push(
        AppRoutes.personalShopProductPath(product.id),
        extra: product,
      ),
      onTryon: () => triggerProductTryon(context, ref, product),
      details: [
        ChatSourceLine(product.storeInfo.name.toUpperCase()),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          product.name,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.neutral40,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          product.price.asTwd,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}
