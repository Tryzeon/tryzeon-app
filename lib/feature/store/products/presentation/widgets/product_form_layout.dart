import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_form.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_basic_info_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_image_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_size_list_editor.dart';

enum ProductFormMode { create, edit }

class ProductFormLayout extends StatelessWidget {
  const ProductFormLayout({
    required this.mode,
    required this.formData,
    required this.sizeManager,
    required this.isLoading,
    required this.onSubmit,
    required this.onPickImage,
    required this.productCategoryTreeAsync,
    required this.onRetryCategories,
    super.key,
  });

  final ProductFormMode mode;
  final ProductFormData formData;
  final ProductSizeManager sizeManager;
  final bool isLoading;
  final VoidCallback onSubmit;
  final Future<List<File>?> Function(int remainingCount) onPickImage;
  final dynamic productCategoryTreeAsync;
  final VoidCallback onRetryCategories;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonText = mode == ProductFormMode.create ? '新增商品' : '儲存變更';

    return Form(
      key: formData.formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FormField<List<ImageItem>>(
            initialValue: formData.images.value,
            validator: (final value) => AppValidators.validateProductImage(
              value,
              isCreateMode: mode == ProductFormMode.create,
            ),
            builder: (final state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImageEditor(
                    images: formData.images.value,
                    onImagesChanged: (final updated) {
                      formData.images.value = updated;
                      state.didChange(updated);
                    },
                    onPickImage: () async {
                      final currentCount = formData.images.value.length;
                      final remainingCount = AppConstants.maxProductImages - currentCount;
                      if (remainingCount <= 0) return;

                      final files = await onPickImage(remainingCount);
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
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        state.errorText!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          ProductBasicInfoEditor(
            nameController: formData.nameController,
            priceController: formData.priceController,
            purchaseLinkController: formData.purchaseLinkController,
            materialController: formData.materialController,
            selectedCategoryIds: formData.selectedCategoryIds,
            selectedElasticity: formData.selectedElasticity,
            selectedFit: formData.selectedFit,
            selectedThickness: formData.selectedThickness,
            selectedStyles: formData.selectedStyles,
            productCategoryTreeAsync: productCategoryTreeAsync,
            onRetryCategories: onRetryCategories,
          ),
          const SizedBox(height: 24),
          ProductSizeListEditor(
            entries: sizeManager.sizeEntries,
            selectedUnit: sizeManager.selectedUnit,
            onUnitChanged: sizeManager.changeUnit,
            onAdd: sizeManager.addSize,
            onRemove: sizeManager.removeSize,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
