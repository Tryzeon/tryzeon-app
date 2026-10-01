import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_frame.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/product_outfit_actions.dart';

class ChatProductCard extends ConsumerWidget {
  const ChatProductCard({super.key, required this.product});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ChatCardFrame(
      image: _ProductImage(product: product),
      onTap: () =>
          context.push(AppRoutes.personalShopProductPath(product.id), extra: product),
      onTryon: () => triggerProductTryon(context, ref, product),
      details: [
        Text(
          product.storeInfo.name,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          product.name,
          style: textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'NT\$${product.price.toStringAsFixed(0)}',
          style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (product.imageUrls.isEmpty) {
      return Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant);
    }
    return CachedNetworkImage(
      imageUrl: product.imageUrls.first,
      cacheKey: product.imagePaths.isNotEmpty ? product.imagePaths.first : null,
      fit: BoxFit.cover,
      placeholder: (final _, final _) => const SizedBox.shrink(),
      errorWidget: (final _, final _, final _) =>
          Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant),
    );
  }
}
