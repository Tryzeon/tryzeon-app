import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/presentation/pages/store_page.dart';

class ProductStoreInfo extends StatelessWidget {
  const ProductStoreInfo({required this.storeInfo, required this.onOpenMap, super.key});

  final ShopStoreInfo storeInfo;
  final VoidCallback? onOpenMap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('店家資訊', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (final context) =>
                      StorePage(storeId: storeInfo.id, initialStoreInfo: storeInfo),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Store Logo
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: storeInfo.logoUrl != null
                        ? CachedNetworkImageProvider(storeInfo.logoUrl!)
                        : null,
                    child: storeInfo.logoUrl == null
                        ? Icon(Icons.store, color: colorScheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storeInfo.name, style: textTheme.titleSmall),
                        if (storeInfo.address != null) ...[
                          const SizedBox(height: 4),
                          Text(storeInfo.address!, style: textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                  if (storeInfo.address != null &&
                      storeInfo.address!.isNotEmpty &&
                      onOpenMap != null)
                    IconButton(
                      onPressed: onOpenMap,
                      icon: Icon(Icons.map, color: colorScheme.primary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
