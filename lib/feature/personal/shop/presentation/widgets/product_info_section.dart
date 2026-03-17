import 'package:flutter/material.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/store/products/presentation/extensions/product_attributes_extension.dart';

class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({required this.product, super.key});

  final ShopProduct product;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('產品資訊', style: textTheme.titleMedium),
        const SizedBox(height: 12),

        if (product.material != null && product.material!.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 60, child: Text('材質', style: textTheme.bodyMedium)),
              Expanded(child: Text(product.material!, style: textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 8),
        ],

        if (product.elasticity != null) ...[
          Row(
            children: [
              SizedBox(width: 60, child: Text('彈性', style: textTheme.bodyMedium)),
              Text(product.elasticity!.label, style: textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
        ],

        if (product.fit != null) ...[
          Row(
            children: [
              SizedBox(width: 60, child: Text('版型', style: textTheme.bodyMedium)),
              Text(product.fit!.label, style: textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
        ],

        if (product.styles != null && product.styles!.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 60, child: Text('風格', style: textTheme.bodyMedium)),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: product.styles!
                      .map(
                        (final s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(s.label, style: textTheme.bodySmall),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
