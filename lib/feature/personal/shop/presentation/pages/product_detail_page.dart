import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/launch_product_purchase.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/share_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_detail_body.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';

class ProductDetailPage extends HookConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productAsync = ref.watch(shopProductByIdProvider(productId));
    final product = productAsync.hasValue ? productAsync.value : null;
    final canShare = product != null;
    final canPurchase = product != null && hasPurchaseLink(product);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.personalHome);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: product != null ? Text(product.name, style: textTheme.titleMedium) : null,
        actions: [
          if (canShare)
            IconButton(
              onPressed: () => shareProduct(product),
              icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS
                    ? Icons.ios_share
                    : Icons.share,
              ),
            ),
          if (canPurchase)
            IconButton(
              onPressed: () => launchProductPurchase(context, ref, product),
              icon: const Icon(Icons.open_in_new),
            ),
        ],
      ),
      body: ProductDetailBody(
        productAsync: productAsync,
        onRetry: () => ref.refresh(shopProductByIdProvider(productId).future),
      ),
    );
  }
}
