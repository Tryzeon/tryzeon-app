import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_grid.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class StorePage extends HookConsumerWidget {
  const StorePage({super.key, required this.storeId, this.initialStoreInfo});

  final String storeId;
  final ShopStoreInfo? initialStoreInfo;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // If not provided from previous page, fetch it
    final storeInfoAsync = initialStoreInfo != null
        ? AsyncValue.data(initialStoreInfo!)
        : ref.watch(storeInfoProvider(storeId));

    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.maybeWhen(
      data: (final profile) => profile,
      orElse: () => null,
    );

    final filter = ShopFilter(storeId: storeId);
    final productsAsync = ref.watch(shopProductsProvider(filter));

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> handleOpenMap(final String address) async {
      final uri = Uri.parse(
        '${AppConstants.googleMapsQueryUrl}${Uri.encodeComponent(address)}',
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
        title: storeInfoAsync.hasValue
            ? Text(storeInfoAsync.value!.name, style: textTheme.titleMedium)
            : const Text('店家'),
        centerTitle: true,
      ),
      body: storeInfoAsync.when(
        data: (final storeInfo) {
          return RefreshIndicator(
            onRefresh: () async {
              if (initialStoreInfo == null) {
                ref.invalidate(storeInfoProvider(storeId));
              }
              return refreshShopProducts(ref, filter);
            },
            color: colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Store Profile Section
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: storeInfo.logoUrl != null
                              ? CachedNetworkImageProvider(storeInfo.logoUrl!)
                              : null,
                          child: storeInfo.logoUrl == null
                              ? Icon(Icons.store, size: 40, color: colorScheme.primary)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(storeInfo.name, style: textTheme.headlineSmall),
                              if (storeInfo.address != null &&
                                  storeInfo.address!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      storeInfo.address!,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => handleOpenMap(storeInfo.address!),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.open_in_new,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('所有商品', style: textTheme.titleLarge),
                  ),
                  // Products Section
                  ProductGrid(
                    productsAsync: productsAsync,
                    userProfile: userProfile,
                    onRetry: () => ref.refresh(shopProductsProvider(filter)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final error, final stack) => ErrorView(
          message: '無法載入店家資訊',
          onRetry: () => ref.refresh(storeInfoProvider(storeId)),
        ),
      ),
    );
  }
}
