import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/controllers/product_size_entry_controller.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_basic_info_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_image_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_size_list_editor.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:typed_result/typed_result.dart'; // For Result extensions

class ProductDetailPage extends HookConsumerWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productCategoriesAsync = ref.watch(productCategoriesProvider);
    final productCategoryTreeAsync = ref.watch(productCategoryTreeProvider);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameController = useTextEditingController(text: product.name);
    final priceController = useTextEditingController(text: product.price.toString());
    final purchaseLinkController = useTextEditingController(text: product.purchaseLink);
    final newImage = useState<File?>(null);
    final isLoading = useState(false);
    final selectedCategoryIds = useValueNotifier<Set<String>>(
      Set<String>.from(product.types),
    );

    final isCun = useState(false);
    final sizeEntries = useState<List<ProductSizeEntryController>>([]);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    useEffect(() {
      final entries = <ProductSizeEntryController>[];
      if (product.sizes != null) {
        for (final size in product.sizes!) {
          entries.add(ProductSizeEntryController.fromProductSize(size));
        }
      }
      sizeEntries.value = entries;

      return () {
        for (final entry in sizeEntries.value) {
          entry.dispose();
        }
      };
    }, const []);

    Future<void> deleteProduct() async {
      final confirm = await ConfirmationDialog.show(
        context: context,
        title: '刪除商品',
        content: '確定要刪除「${product.name}」嗎?',
        confirmText: '刪除',
      );

      if (confirm != true) return;

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
      if (!formKey.currentState!.validate()) return;

      if (selectedCategoryIds.value.isEmpty) {
        TopNotification.show(
          context,
          message: '請至少選擇一個類型',
          type: NotificationType.warning,
        );
        return;
      }

      isLoading.value = true;

      final targetProduct = Product(
        storeId: product.storeId,
        name: nameController.text,
        types: selectedCategoryIds.value,
        price: double.parse(priceController.text),
        imagePath: product.imagePath,
        imageUrl: product.imageUrl,
        id: product.id,
        purchaseLink: purchaseLinkController.text,
        sizes: sizeEntries.value
            .map((final e) => e.toProductSize(product.id!, isCun: isCun.value))
            .toList(),
      );

      final updateProductUseCase = ref.read(updateProductUseCaseProvider);
      final result = await updateProductUseCase(
        original: product,
        target: targetProduct,
        newImage: newImage.value,
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

    void addSize() {
      sizeEntries.value = [...sizeEntries.value, ProductSizeEntryController()];
    }

    void removeSize(final int index) {
      sizeEntries.value[index].dispose();
      final newList = [...sizeEntries.value];
      newList.removeAt(index);
      sizeEntries.value = newList;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('商品資訊', style: textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.onSurfaceVariant),
            onPressed: deleteProduct,
            tooltip: '刪除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImageEditor(
                selectedImage: newImage.value,
                existingImageUrl: product.imageUrl,
                existingImagePath: product.imagePath,
                onPickImage: () async {
                  final image = await ImagePickerHelper.pickImage(context);
                  if (image != null) {
                    newImage.value = image;
                  }
                },
              ),
              const SizedBox(height: 24),
              ProductBasicInfoEditor(
                nameController: nameController,
                priceController: priceController,
                purchaseLinkController: purchaseLinkController,
                selectedCategoryIds: selectedCategoryIds,
                productCategoriesAsync: productCategoriesAsync,
                productCategoryTreeAsync: productCategoryTreeAsync,
                onRetryCategories: () => ref.refresh(productCategoriesProvider),
              ),
              const SizedBox(height: 24),

              Container(
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
                child: ProductSizeListEditor(
                  entries: sizeEntries.value,
                  isCun: isCun.value,
                  onUnitChanged: (final val) {
                    isCun.value = val;
                    for (final entry in sizeEntries.value) {
                      entry.convertValues(toCun: val);
                    }
                  },
                  onAdd: addSize,
                  onRemove: removeSize,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading.value ? null : updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          '儲存變更',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
