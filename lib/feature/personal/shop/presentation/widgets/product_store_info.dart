import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';

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
        Text('店家資訊', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
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
                  Text(
                    storeInfo.name,
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (storeInfo.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      storeInfo.address!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
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
      ],
    );
  }
}
