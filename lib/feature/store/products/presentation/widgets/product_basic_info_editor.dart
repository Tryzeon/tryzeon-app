import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

import 'package:tryzeon/feature/store/products/presentation/extensions/product_attributes_extension.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_category_selector.dart';

class ProductBasicInfoEditor extends StatelessWidget {
  const ProductBasicInfoEditor({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.purchaseLinkController,
    required this.selectedCategoryIds,
    required this.selectedElasticity,
    required this.selectedFit,

    required this.productCategoryTreeAsync,
    required this.onRetryCategories,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchaseLinkController;
  final ValueNotifier<Set<String>> selectedCategoryIds;
  final ValueNotifier<ProductElasticity?> selectedElasticity;
  final ValueNotifier<ProductFit?> selectedFit;

  final AsyncValue<List<CategoryTreeNode>> productCategoryTreeAsync;
  final VoidCallback onRetryCategories;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('商品資訊', style: textTheme.titleSmall),
          const SizedBox(height: 16),
          TextFormField(
            controller: nameController,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: '商品名稱',
              labelStyle: textTheme.bodyMedium,
              prefixIcon: Icon(Icons.shopping_bag_outlined, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
            ),
            validator: AppValidators.validateProductName,
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '商品類型',
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Text('(可多選)', style: textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 12),
              productCategoryTreeAsync.when(
                data: (final categoryTree) {
                  return ProductCategorySelector(
                    categoryTree: categoryTree,
                    selectedCategoryIds: selectedCategoryIds,
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (final error, final stack) => ErrorView(
                  message: (error as Failure).displayMessage(context),
                  onRetry: onRetryCategories,
                  isCompact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: priceController,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: '價格',
              labelStyle: textTheme.bodyMedium,
              prefixIcon: Icon(Icons.attach_money_rounded, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            validator: AppValidators.validatePrice,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: purchaseLinkController,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: '導購連結',
              hintText: 'https://...',
              labelStyle: textTheme.bodyMedium,
              prefixIcon: Icon(Icons.link_rounded, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
            ),
            keyboardType: TextInputType.url,
            validator: AppValidators.validateUrl,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ProductElasticity>(
                  initialValue: selectedElasticity.value,
                  decoration: InputDecoration(
                    labelText: '彈性',
                    labelStyle: textTheme.bodyMedium,
                    prefixIcon: Icon(Icons.waves, color: colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                  ),
                  isExpanded: true,
                  items: ProductElasticity.values.map((final e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(
                        e.label,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge,
                      ),
                    );
                  }).toList(),
                  onChanged: (final value) {
                    selectedElasticity.value = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<ProductFit>(
                  initialValue: selectedFit.value,
                  decoration: InputDecoration(
                    labelText: '版型',
                    labelStyle: textTheme.bodyMedium,
                    prefixIcon: Icon(Icons.accessibility_new, color: colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                  ),
                  isExpanded: true,
                  items: ProductFit.values.map((final f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(
                        f.label,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge,
                      ),
                    );
                  }).toList(),
                  onChanged: (final value) {
                    selectedFit.value = value;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
