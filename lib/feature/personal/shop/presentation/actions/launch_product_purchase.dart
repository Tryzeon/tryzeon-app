import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/common/store/domain/entities/order_contact_type.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/order_message_builder.dart';
import 'package:tryzeon/feature/personal/shop/presentation/sheets/pre_purchase_sheet.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:url_launcher/url_launcher.dart';

bool productHasPurchaseOptions(final ShopProduct product) =>
    (product.purchaseLink != null && product.purchaseLink!.isNotEmpty) ||
    product.storeInfo.orderContacts.isNotEmpty;

Future<void> launchProductPurchase(
  final BuildContext context,
  final WidgetRef ref,
  final ShopProduct product,
  final FitResult fitResult,
) async {
  if (!productHasPurchaseOptions(product)) return;

  final choice = await PrePurchaseSheet.show(
    context: context,
    product: product,
    fitResult: fitResult,
  );
  if (choice == null || !context.mounted) return;

  final target = _resolveTarget(choice, product, fitResult);

  final trackPurchaseClick = ref.read(trackProductPurchaseClickProvider);

  if (!await canLaunchUrl(target.uri)) {
    if (context.mounted) {
      TopNotification.show(context, message: target.failureMessage);
    }
    return;
  }

  trackPurchaseClick(product);
  await launchUrl(target.uri, mode: LaunchMode.externalApplication);
}

({Uri uri, String failureMessage}) _resolveTarget(
  final PurchaseChoice choice,
  final ShopProduct product,
  final FitResult fitResult,
) {
  switch (choice) {
    case OnlineStoreChoice():
      return (
        uri: Uri.parse(product.purchaseLink!),
        failureMessage: '無法開啟購買連結',
      );
    case ContactChoice(:final type, :final value):
      final message = OrderMessageBuilder.build(
        product: product,
        fitResult: fitResult,
      );
      return (
        uri: _buildOrderContactUri(type, value, message),
        failureMessage: '無法開啟 ${type.label} 聊天室',
      );
  }
}

Uri _buildOrderContactUri(
  final OrderContactType type,
  final String value,
  final String message,
) {
  switch (type) {
    case OrderContactType.line:
      // The '@' prefix marks an Official Account, whose deep link can prefill;
      // a bare ID resolves to a personal add-friend link that cannot.
      return value.startsWith('@')
          ? Uri.parse(
              'https://line.me/R/oaMessage/$value/?${Uri.encodeComponent(message)}',
            )
          : Uri.parse('https://line.me/ti/p/~$value');
    case OrderContactType.facebook:
      return Uri.parse('https://m.me/$value');
    case OrderContactType.instagram:
      return Uri.parse('https://ig.me/m/$value');
  }
}
