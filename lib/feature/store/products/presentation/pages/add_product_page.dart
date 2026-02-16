import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';

import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_form.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_form_layout.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class AddProductPage extends HookConsumerWidget {
  const AddProductPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formData = useProductForm();
    final sizeManager = useProductSizeManager();
    final isLoading = useState(false);
    final productCategoryTreeAsync = ref.watch(productCategoryTreeProvider);

    bool validateProductForm() {
      if (formData.selectedImage.value == null) {
        TopNotification.show(context, message: '請選擇商品圖片', type: NotificationType.warning);
        return false;
      }

      if (formData.selectedCategoryIds.value.isEmpty) {
        TopNotification.show(
          context,
          message: '請至少選擇一種商品類型',
          type: NotificationType.warning,
        );
        return false;
      }

      return true;
    }

    Future<void> addProduct() async {
      if (!formData.validate(context)) return;
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
        isLoading.value = false;
        return;
      }

      final newProduct = formData.toProduct(
        id: '',
        storeId: storeProfile.id,
        imagePath: '',
        imageUrl: '',
        sizes: sizeManager.buildProductSizes(null),
      );

      final createProductUseCase = ref.read(createProductUseCaseProvider);
      final result = await createProductUseCase(
        product: newProduct,
        image: formData.selectedImage.value!,
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

    return ProductFormLayout(
      mode: ProductFormMode.create,
      formData: formData,
      sizeManager: sizeManager,
      isLoading: isLoading.value,
      onSubmit: addProduct,
      productCategoryTreeAsync: productCategoryTreeAsync,
      onRetryCategories: () => ref.refresh(productCategoriesProvider),
      onPickImage: () async {
        final image = await ImagePickerHelper.pickImage(context);
        if (image != null) {
          formData.selectedImage.value = image;
        }
      },
    );
  }
}
