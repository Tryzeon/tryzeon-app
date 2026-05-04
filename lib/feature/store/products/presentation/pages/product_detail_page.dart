import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
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
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    final product = productAsync.hasValue ? productAsync.requireValue : null;

    if (product != null) {
      return _ProductDetailContentPage(key: ValueKey(product.id), product: product);
    }

    return _ProductDetailFallbackPage(
      isLoading: productAsync.isLoading,
      error: productAsync.error,
      onRetry: () => ref.invalidate(productByIdProvider(productId)),
    );
  }
}

class _ProductDetailFallbackPage extends StatelessWidget {
  const _ProductDetailFallbackPage({
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品詳情')),
      body: isLoading
          ? const _ProductDetailLoadingView()
          : ErrorView(message: error.displayMessage(context), onRetry: onRetry),
    );
  }
}

class _ProductDetailLoadingView extends StatelessWidget {
  const _ProductDetailLoadingView();

  @override
  Widget build(final BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ProductDetailContentPage extends HookConsumerWidget {
  const _ProductDetailContentPage({super.key, required this.product});

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
        context.pop(true);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
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
        params: UpdateProductParams(
          productId: product.id,
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
          material: formData.effectiveMaterial,
          elasticity: formData.selectedElasticity.value,
          fit: formData.effectiveFit,
          thickness: formData.selectedThickness.value,
          styles: formData.selectedStyles.value,
          seasons: formData.selectedSeasons.value,
        ),
      );

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        context.pop(true);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯商品'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: deleteProduct,
            tooltip: '刪除',
          ),
        ],
      ),
      body: ProductFormLayout(
        mode: ProductFormMode.edit,
        formData: formData,
        sizeManager: sizeManager,
        isLoading: isLoading.value,
        onSubmit: updateProduct,
        productCategoryTreeAsync: productCategoryTreeAsync,
        onRetryCategories: () => refreshProductCategories(ref),
        onPickImage: (final remainingCount) async {
          return ImagePickerHelper.pickImages(context, maxImages: remainingCount);
        },
      ),
    );
  }
}
