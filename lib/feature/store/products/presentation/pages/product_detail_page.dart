import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_form.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_form_layout.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:typed_result/typed_result.dart';

class ProductDetailPage extends HookConsumerWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formData = useProductForm(initialProduct: product);
    final sizeManager = useProductSizeManager(initialSizes: product.sizes);
    final isLoading = useState(false);
    final productCategoryTreeAsync = ref.watch(productCategoryTreeProvider);

    Future<void> deleteProduct() async {
      final dialogResult = await showOkCancelAlertDialog(
        context: context,
        title: '刪除商品',
        message: '確定要刪除「${product.name}」嗎?',
        okLabel: '刪除',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );

      if (dialogResult != OkCancelResult.ok) return;

      isLoading.value = true;

      final deleteProductUseCase = ref.read(deleteProductUseCaseProvider);
      final result = await deleteProductUseCase(product);

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        TopNotification.show(context, message: '商品刪除成功', type: NotificationType.success);
        Navigator.pop(context, true);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
          type: NotificationType.error,
        );
      }
    }

    Future<void> updateProduct() async {
      if (!formData.validate(context)) return;

      isLoading.value = true;

      final deltas = sizeManager.calculateDeltas(product.id, product.sizes);

      final updateProductUseCase = ref.read(updateProductUseCaseProvider);
      final result = await updateProductUseCase(
        original: product,
        finalImageOrder: formData.images.value,
        sizesToAdd: deltas.sizesToAdd,
        sizesToUpdate: deltas.sizesToUpdate,
        sizeIdsToDelete: deltas.sizeIdsToDelete,
        name: formData.nameController.text,
        categoryIds: formData.selectedCategoryIds.value.toList(),
        price: double.tryParse(formData.priceController.text) ?? 0.0,
        purchaseLink: formData.purchaseLinkController.text.isNotEmpty
            ? formData.purchaseLinkController.text
            : null,
        material: formData.materialController.text.isNotEmpty
            ? formData.materialController.text
            : null,
        elasticity: formData.selectedElasticity.value,
        fit: formData.selectedFit.value,
        styles: formData.selectedStyles.value,
      );

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        Navigator.pop(context, true);
        TopNotification.show(context, message: '商品更新成功', type: NotificationType.success);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
          type: NotificationType.error,
        );
      }
    }

    return ProductFormLayout(
      mode: ProductFormMode.edit,
      formData: formData,
      sizeManager: sizeManager,
      isLoading: isLoading.value,
      onSubmit: updateProduct,
      onDelete: deleteProduct,
      productCategoryTreeAsync: productCategoryTreeAsync,
      onRetryCategories: () => ref.refresh(productCategoriesProvider),
      onPickImage: () async {
        return ImagePickerHelper.pickImages(context);
      },
    );
  }
}
