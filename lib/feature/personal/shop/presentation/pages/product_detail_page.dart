import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_detail_body.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends HookConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productAsync = ref.watch(shopProductProvider(productId));
    final product = productAsync.hasValue ? productAsync.value : null;
    final hasPurchaseLink =
        product != null &&
        product.purchaseLink != null &&
        product.purchaseLink!.isNotEmpty;

    Future<void> handlePurchase() async {
      if (!hasPurchaseLink) return;

      final Uri url = Uri.parse(product.purchaseLink!);
      if (!await canLaunchUrl(url)) {
        if (!context.mounted) return;
        TopNotification.show(context, message: '無法開啟購買連結', type: NotificationType.error);
        return;
      }

      // 記錄購買連結點擊次數 (非同步執行，不阻塞 UI)
      ref
          .read(incrementPurchaseClickCountProvider)
          .call(productId: product.id, storeId: product.storeInfo.id)
          .ignore();
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('商品詳情', style: Theme.of(context).textTheme.titleMedium),
        centerTitle: true,
        actions: [
          if (productAsync.hasValue)
            IconButton(
              onPressed: () {
                final product = productAsync.value!;
                share_plus.SharePlus.instance.share(
                  share_plus.ShareParams(
                    text: '${AppConstants.webBaseUrl}/product/${product.id}',
                  ),
                );
              },
              icon: const Icon(Icons.share),
            ),
          if (hasPurchaseLink)
            IconButton(onPressed: handlePurchase, icon: const Icon(Icons.open_in_new)),
        ],
      ),
      body: ProductDetailBody(
        productAsync: productAsync,
        onRetry: () => ref.refresh(shopProductProvider(productId).future),
      ),
    );
  }
}
