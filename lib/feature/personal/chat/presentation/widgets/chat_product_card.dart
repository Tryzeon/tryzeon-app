import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/router/app_routes.dart';
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
    return ChatCardFrame(
      image: ChatProductImage(product: product),
      highlight: highlight,
      onTap: () => context.push(
        AppRoutes.personalShopProductPath(product.id),
        extra: product,
      ),
      onTryon: () => triggerProductTryon(context, ref, product),
      source: product.storeInfo.name.toUpperCase(),
      name: product.name,
      value: product.price.asTwd,
    );
  }
}
