import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

import 'package:tryzeon/feature/store/products/presentation/extensions/product_attributes_extension.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_category_selector.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_season_selector.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_style_selector.dart';

class ProductBasicInfoEditor extends StatelessWidget {
  const ProductBasicInfoEditor({
    super.key,
    required this.nameController,
    required this.priceController,
    required this.purchaseLinkController,
    required this.selectedMaterialPreset,
    required this.materialOtherController,
    required this.selectedFitPreset,
    required this.fitOtherController,
    required this.selectedCategoryIds,
    required this.selectedElasticity,
    required this.selectedThickness,
    required this.selectedStyles,
    required this.selectedSeasons,
    required this.productCategoryTreeAsync,
    required this.onRetryCategories,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchaseLinkController;
  final ValueNotifier<String?> selectedMaterialPreset;
  final TextEditingController materialOtherController;
  final ValueNotifier<String?> selectedFitPreset;
  final TextEditingController fitOtherController;
  final ValueNotifier<Set<String>> selectedCategoryIds;
  final ValueNotifier<ProductElasticity?> selectedElasticity;
  final ValueNotifier<ProductThickness?> selectedThickness;
  final ValueNotifier<List<ClothingStyle>?> selectedStyles;
  final ValueNotifier<List<ProductSeason>?> selectedSeasons;

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
                  Text('商品類型', style: textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              productCategoryTreeAsync.when(
                data: (final categoryTree) {
                  return FormField<Set<String>>(
                    initialValue: selectedCategoryIds.value,
                    validator: AppValidators.validateSelectedCategories,
                    builder: (final state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductCategorySelector(
                            categoryTree: categoryTree,
                            selectedCategoryIds: selectedCategoryIds,
                            onChanged: (final newIds) {
                              selectedCategoryIds.value = newIds;
                              state.didChange(newIds);
                            },
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 12),
                              child: Text(
                                state.errorText!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (final error, final stack) => ErrorView(
                  message: error.displayMessage(context),
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
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.style_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('風格標籤 (選填)', style: textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              FormField<List<ClothingStyle>?>(
                initialValue: selectedStyles.value,
                builder: (final state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductStyleSelector(
                        selectedStyles: selectedStyles,
                        onChanged: (final newStyles) {
                          selectedStyles.value = newStyles;
                          state.didChange(newStyles);
                        },
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            state.errorText!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: purchaseLinkController,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: '導購連結 (選填)',
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
          const SizedBox(height: 12),
          ValueListenableBuilder<String?>(
            valueListenable: selectedMaterialPreset,
            builder: (final context, final materialPreset, final _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: materialPreset,
                    decoration: InputDecoration(
                      labelText: '材質 (選填)',
                      labelStyle: textTheme.bodyMedium,
                      prefixIcon: Icon(Icons.texture, color: colorScheme.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainer,
                    ),
                    isExpanded: true,
                    items: [
                      ...kMaterialPresets.map(
                        (final label) => DropdownMenuItem(
                          value: label,
                          child: Text(label, style: textTheme.bodyLarge),
                        ),
                      ),
                      DropdownMenuItem(
                        value: kOtherSentinel,
                        child: Text('其他 (自行輸入)', style: textTheme.bodyLarge),
                      ),
                    ],
                    onChanged: (final value) {
                      selectedMaterialPreset.value = value;
                      if (value != kOtherSentinel) {
                        materialOtherController.clear();
                      }
                    },
                  ),
                  if (materialPreset == kOtherSentinel) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: materialOtherController,
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: '請輸入材質',
                        hintText: '塑膠、再生纖維…',
                        labelStyle: textTheme.bodyMedium,
                        prefixIcon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainer,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProductElasticity>(
            initialValue: selectedElasticity.value,
            decoration: InputDecoration(
              labelText: '彈性 (選填)',
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
          const SizedBox(height: 12),
          ValueListenableBuilder<String?>(
            valueListenable: selectedFitPreset,
            builder: (final context, final fitPreset, final _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: fitPreset,
                    decoration: InputDecoration(
                      labelText: '版型 (選填)',
                      labelStyle: textTheme.bodyMedium,
                      prefixIcon: Icon(
                        Icons.accessibility_new,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainer,
                    ),
                    isExpanded: true,
                    items: [
                      ...kFitPresets.map(
                        (final preset) => DropdownMenuItem(
                          value: preset,
                          child: Text(
                            preset,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: kOtherSentinel,
                        child: Text(
                          '其他 (自行輸入)',
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ],
                    onChanged: (final value) {
                      selectedFitPreset.value = value;
                      if (value != kOtherSentinel) {
                        fitOtherController.clear();
                      }
                    },
                  ),
                  if (fitPreset == kOtherSentinel) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: fitOtherController,
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: '請輸入版型',
                        hintText: '不規則剪裁…',
                        labelStyle: textTheme.bodyMedium,
                        prefixIcon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainer,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProductThickness>(
            initialValue: selectedThickness.value,
            decoration: InputDecoration(
              labelText: '厚薄度 (選填)',
              labelStyle: textTheme.bodyMedium,
              prefixIcon: Icon(Icons.layers_outlined, color: colorScheme.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
            ),
            isExpanded: true,
            items: ProductThickness.values.map((final t) {
              return DropdownMenuItem(
                value: t,
                child: Text(
                  t.label,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge,
                ),
              );
            }).toList(),
            onChanged: (final value) {
              selectedThickness.value = value;
            },
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('季節 (選填)', style: textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              ProductSeasonSelector(
                selectedSeasons: selectedSeasons,
                onChanged: (final newSeasons) {
                  selectedSeasons.value = newSeasons;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
