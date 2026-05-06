import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/category_tree_node.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_form.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_advanced_fields_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_basic_fields_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_image_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_size_list_editor.dart';

class ProductFormLayout extends StatelessWidget {
  const ProductFormLayout({
    required this.formData,
    required this.sizeManager,
    required this.isLoading,
    required this.onPickImage,
    required this.productCategoryTreeAsync,
    required this.onRetryCategories,
    this.onDelete,
    super.key,
  });
  final ProductFormData formData;
  final ProductSizeManager sizeManager;
  final bool isLoading;
  final Future<List<File>?> Function(int remainingCount) onPickImage;
  final AsyncValue<List<CategoryTreeNode>> productCategoryTreeAsync;
  final VoidCallback onRetryCategories;
  final VoidCallback? onDelete;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: formData.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.smMd,
            ),
            child: _FormSectionLabel(
              number: '01',
              title: '商品圖片',
              helper: '最多 3 張 · 長按拖曳調整順序',
            ),
          ),
          FormField<List<ImageItem>>(
            initialValue: formData.images.value,
            validator: AppValidators.validateProductImage,
            builder: (final state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageEditor(
                  images: formData.images.value,
                  hasError: state.hasError,
                  onImagesChanged: (final updated) {
                    formData.images.value = updated;
                    state.didChange(updated);
                  },
                  onPickImage: () async {
                    final currentCount = formData.images.value.length;
                    final remaining = AppConstants.maxProductImages - currentCount;
                    if (remaining <= 0) return;
                    final files = await onPickImage(remaining);
                    if (files != null && files.isNotEmpty) {
                      final newItems = files
                          .map((final f) => ImageItem.newImage(file: f))
                          .toList();
                      final updated = [...formData.images.value, ...newItems];
                      formData.images.value = updated;
                      state.didChange(updated);
                    }
                  },
                ),
                if (state.hasError) _ImageErrorText(state.errorText!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _FormSectionLabel(number: '02', title: '商品資訊'),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductBasicFieldsEditor(
                  nameController: formData.nameController,
                  priceController: formData.priceController,
                  purchaseLinkController: formData.purchaseLinkController,
                  selectedCategoryIds: formData.selectedCategoryIds,
                  productCategoryTreeAsync: productCategoryTreeAsync,
                  onRetryCategories: onRetryCategories,
                ),
                const SizedBox(height: AppSpacing.lg),
                ProductAdvancedFieldsEditor(
                  selectedMaterial: formData.selectedMaterial,
                  selectedFit: formData.selectedFit,
                  selectedElasticity: formData.selectedElasticity,
                  selectedThickness: formData.selectedThickness,
                  selectedStyles: formData.selectedStyles,
                  selectedSeasons: formData.selectedSeasons,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _FormSectionLabel(number: '03', title: '尺寸資訊'),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ProductSizeListEditor(
              entries: sizeManager.sizeEntries,
              selectedUnit: sizeManager.selectedUnit,
              onUnitChanged: sizeManager.changeUnit,
              onAdd: sizeManager.addSize,
              onRemove: sizeManager.removeSize,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '危險操作',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: colorScheme.error),
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      child: const Text('刪除商品'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel({required this.number, required this.title, this.helper});

  final String number;
  final String title;
  final String? helper;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(number, style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
        const SizedBox(height: AppSpacing.xs),
        Text(title, style: textTheme.titleMedium),
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helper!,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _ImageErrorText extends StatelessWidget {
  const _ImageErrorText(this.text);

  final String text;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}
