import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/main/personal_entry_scope.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_detail_body.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/providers/subscription_capabilities_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends HookConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productAsync = ref.watch(shopProductByIdProvider(productId));
    final product = productAsync.hasValue ? productAsync.value : null;
    final hasPurchaseLink =
        product != null &&
        product.purchaseLink != null &&
        product.purchaseLink!.isNotEmpty;

    final capabilitiesAsync = ref.watch(subscriptionCapabilitiesProvider);
    final hasVideoAccess = capabilitiesAsync.maybeWhen(
      data: (final capabilities) => capabilities.hasVideoAccess,
      orElse: () => false,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

    Future<void> handleTryon({final TryOnMode mode = TryOnMode.image}) async {
      if (product == null) return;

      // 記錄虛擬試穿點擊次數
      ref
          .read(incrementTryonCountProvider)
          .call(productId: product.id, storeId: product.storeInfo.id)
          .ignore();

      if (!context.mounted) return;

      final personalEntry = PersonalEntryScope.of(context);
      await personalEntry?.tryOnFromStorage(product.imagePaths, mode: mode);
    }

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
        centerTitle: true,
        actions: [
          if (productAsync.hasValue)
            IconButton(
              onPressed: () {
                final p = productAsync.value!;
                share_plus.SharePlus.instance.share(
                  share_plus.ShareParams(
                    text: '${AppConstants.webBaseUrl}/product/${p.id}',
                  ),
                );
              },
              icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS
                    ? Icons.ios_share
                    : Icons.share,
              ),
            ),
        ],
      ),
      body: ProductDetailBody(
        productAsync: productAsync,
        onRetry: () => ref.refresh(shopProductByIdProvider(productId).future),
      ),
      // Sticky bottom bar with price + Try-On CTA
      bottomNavigationBar: product != null
          ? Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outline, width: 1)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.smMd,
                  ),
                  child: Row(
                    children: [
                      // Price and purchase link
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${product.price}',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            if (hasPurchaseLink)
                              GestureDetector(
                                onTap: handlePurchase,
                                child: Text(
                                  '前往購買',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Try-on CTA button
                      FilledButton.icon(
                        onPressed: () {
                          TryOnModeSheet.show(
                            context: context,
                            hasVideoAccess: hasVideoAccess,
                            onModeSelected: (final mode) => handleTryon(mode: mode),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('AI 試穿'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
