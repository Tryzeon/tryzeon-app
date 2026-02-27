import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_header.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_info_section.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_size_table.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_store_info.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends HookConsumerWidget {
  const ProductDetailPage({super.key, required this.product});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Build category ID to name mapping
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final categoryIdToName = categoriesAsync.maybeWhen(
      data: (final categories) => {for (final cat in categories) cat.id: cat.name},
      orElse: () => <String, String>{},
    );

    Future<void> handlePurchase() async {
      if (product.purchaseLink == null || product.purchaseLink!.isEmpty) {
        TopNotification.show(context, message: '此商品尚無購買連結', type: NotificationType.info);
        return;
      }

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
          IconButton(onPressed: handlePurchase, icon: const Icon(Icons.open_in_new)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header (Image, Categories, Name, Price)
            ProductHeader(product: product, categoryIdToName: categoryIdToName),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 20),

                  // Store Info Section
                  ProductStoreInfo(storeInfo: product.storeInfo),
                  const SizedBox(height: 32),

                  // Product Info Section (Material, Elasticity, Fit)
                  if (product.elasticity != null ||
                      product.fit != null ||
                      (product.material != null && product.material!.isNotEmpty)) ...[
                    ProductInfoSection(product: product),
                    const SizedBox(height: 32),
                  ],

                  // Size Info Section
                  if (product.sizes != null && product.sizes!.isNotEmpty) ...[
                    ProductSizeTable(sizes: product.sizes!),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
