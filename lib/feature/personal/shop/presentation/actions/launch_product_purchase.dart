import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:url_launcher/url_launcher.dart';

bool hasPurchaseLink(final ShopProduct product) =>
    product.purchaseLink != null && product.purchaseLink!.isNotEmpty;

Future<void> launchProductPurchase(
  final BuildContext context,
  final WidgetRef ref,
  final ShopProduct product,
) async {
  if (!hasPurchaseLink(product)) return;

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
