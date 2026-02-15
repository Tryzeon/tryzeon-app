import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/shared/measurements/presentation/mappers/measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:tryzeon/feature/store/products/presentation/extensions/product_attributes_extension.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends HookConsumerWidget {
  const ProductDetailPage({super.key, required this.product});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

    Future<void> handleOpenMap() async {
      final address = product.storeInfo.address!;

      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
      if (!await canLaunchUrl(uri)) {
        if (!context.mounted) return;
        TopNotification.show(context, message: '無法開啟地圖', type: NotificationType.error);
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            // Product Image with Zoom
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (final context) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        iconTheme: const IconThemeData(color: Colors.white),
                      ),
                      body: Center(
                        child: InteractiveViewer(
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            cacheKey: product.imagePath,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (final context, final url) =>
                                const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  cacheKey: product.imagePath,
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                  placeholder: (final context, final url) => Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  ),
                  errorWidget: (final context, final url, final error) => Container(
                    height: 400,
                    color: colorScheme.surfaceContainer,
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Attributes (Categories + Elasticity + Fit)
                  if (product.categories.isNotEmpty ||
                      product.elasticity != null ||
                      product.fit != null) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Categories
                        ...product.categories.map((final typeId) {
                          final categoryName = categoryIdToName[typeId] ?? typeId;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              categoryName,
                              style: textTheme.labelMedium,
                            ),
                          );
                        }),
                        // Elasticity
                        if (product.elasticity != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.waves,
                                  size: 14,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '彈性: ${product.elasticity!.label}',
                                  style: textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        // Fit
                        if (product.fit != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.accessibility_new,
                                  size: 14,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '版型: ${product.fit!.label}',
                                  style: textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Product Name
                  Text(
                    product.name,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    '\$${product.price}',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Size Info Section
                  if (product.sizes != null && product.sizes!.isNotEmpty) ...[
                    Text(
                      '尺寸資訊',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        columns: [
                          const DataColumn(label: Text('尺寸')),
                          ...MeasurementType.values.map(
                            (final type) => DataColumn(label: Text(type.label)),
                          ),
                        ],
                        rows: product.sizes!.map((final size) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  size.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...MeasurementType.values.map((final type) {
                                final measurements = size.measurements;
                                final value = measurements?.getValue(type);
                                return DataCell(
                                  Text(value != null ? value.toStringAsFixed(1) : '-'),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '* 此尺寸數據為手工測量，可能存在些許誤差',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],

                  // Store Info Section
                  Text(
                    '店家資訊',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Store Logo
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        backgroundImage: product.storeInfo.logoUrl != null
                            ? CachedNetworkImageProvider(product.storeInfo.logoUrl!)
                            : null,
                        child: product.storeInfo.logoUrl == null
                            ? Icon(Icons.store, color: colorScheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.storeInfo.name,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (product.storeInfo.address != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                product.storeInfo.address!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (product.storeInfo.address != null &&
                          product.storeInfo.address!.isNotEmpty)
                        IconButton(
                          onPressed: handleOpenMap,
                          icon: Icon(Icons.map, color: colorScheme.primary),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
