import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/controllers/product_size_entry_controller.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_basic_info_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_image_editor.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_size_list_editor.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class AddProductPage extends HookConsumerWidget {
  const AddProductPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final productCategoryTreeAsync = ref.watch(productCategoryTreeProvider);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final purchaseLinkController = useTextEditingController();

    final selectedImage = useState<File?>(null);
    final selectedCategoryIds = useValueNotifier<Set<String>>({});

    final isCun = useState(false);
    final sizeEntries = useState<List<ProductSizeEntryController>>([]);
    final isLoading = useState(false);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    useEffect(() {
      return () {
        for (final entry in sizeEntries.value) {
          entry.dispose();
        }
      };
    }, const []);

    void addSizeBlock() {
      sizeEntries.value = [...sizeEntries.value, ProductSizeEntryController()];
    }

    void removeSizeBlock(final int index) {
      sizeEntries.value[index].dispose();
      final newList = [...sizeEntries.value];
      newList.removeAt(index);
      sizeEntries.value = newList;
    }

    List<ProductSize> buildProductSizes() {
      return sizeEntries.value
          .map((final entry) => entry.toProductSize(null, isCun: isCun.value))
          .toList();
    }

    bool validateProductForm() {
      if (selectedImage.value == null) {
        TopNotification.show(context, message: '請選擇商品圖片', type: NotificationType.warning);
        return false;
      }

      if (selectedCategoryIds.value.isEmpty) {
        TopNotification.show(
          context,
          message: '請至少選擇一種商品類型',
          type: NotificationType.warning,
        );
        return false;
      }

      return true;
    }

    Future<void> handleAddProduct() async {
      if (!formKey.currentState!.validate()) return;
      if (!validateProductForm()) return;

      isLoading.value = true;

      final storeProfile = await ref.read(storeProfileProvider.future);
      if (!context.mounted) return;

      if (storeProfile == null) {
        TopNotification.show(
          context,
          message: '無法獲取店家資訊，請重新登入',
          type: NotificationType.error,
        );
        return;
      }

      final newProduct = Product(
        storeId: storeProfile.id,
        name: nameController.text,
        types: selectedCategoryIds.value,
        price: double.parse(priceController.text),
        purchaseLink: purchaseLinkController.text,
        imagePath: '',
        imageUrl: '',
        sizes: buildProductSizes(),
      );

      final createProductUseCase = ref.read(createProductUseCaseProvider);
      final result = await createProductUseCase(
        product: newProduct,
        image: selectedImage.value!,
      );

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        Navigator.pop(context, true);
        TopNotification.show(context, message: '商品新增成功', type: NotificationType.success);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
          type: NotificationType.error,
        );
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('新增商品', style: textTheme.headlineMedium),
                          Text('新增商品到您的店家', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      ProductImageEditor(
                        selectedImage: selectedImage.value,
                        onPickImage: () async {
                          final image = await ImagePickerHelper.pickImage(context);
                          if (image != null) {
                            selectedImage.value = image;
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ProductBasicInfoEditor(
                        nameController: nameController,
                        priceController: priceController,
                        purchaseLinkController: purchaseLinkController,
                        selectedCategoryIds: selectedCategoryIds,

                        productCategoryTreeAsync: productCategoryTreeAsync,
                        onRetryCategories: () => ref.refresh(productCategoriesProvider),
                      ),
                      const SizedBox(height: 16),
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
                          onAdd: addSizeBlock,
                          onRemove: removeSizeBlock,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isLoading.value
                              ? colorScheme.outline
                              : colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isLoading.value
                              ? []
                              : [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoading.value ? null : handleAddProduct,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: isLoading.value
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_rounded,
                                          color: colorScheme.onPrimary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '新增商品',
                                          style: textTheme.titleMedium?.copyWith(
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
