import 'package:flutter/material.dart';
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
    this.existingImageUrl,
    this.existingImagePath,
    this.onDelete,
    super.key,
  });

  final ProductFormMode mode;
  final ProductFormData formData;
  final ProductSizeManager sizeManager;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onPickImage;
  final dynamic productCategoryTreeAsync;
  final VoidCallback onRetryCategories;
  final String? existingImageUrl;
  final String? existingImagePath;
  final VoidCallback? onDelete;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final title = mode == ProductFormMode.create ? '新增商品' : '編輯商品';
    final buttonText = mode == ProductFormMode.create ? '新增商品' : '儲存變更';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: '刪除',
            ),
        ],
      ),
      body: Form(
        key: formData.formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ProductImageEditor(
              selectedImage: formData.selectedImage.value,
              existingImageUrl: existingImageUrl,
              existingImagePath: existingImagePath,
              onPickImage: onPickImage,
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
              productCategoryTreeAsync: productCategoryTreeAsync,
              onRetryCategories: onRetryCategories,
            ),
            const SizedBox(height: 24),
            ProductSizeListEditor(
              entries: sizeManager.sizeEntries,
              isCun: sizeManager.isCun,
              onUnitChanged: sizeManager.toggleUnit,
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
      ),
    );
  }
}
