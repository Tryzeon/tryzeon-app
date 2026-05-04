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

    Future<void> addProduct() async {
      if (!formData.validate(context)) return;

      isLoading.value = true;

      final storeProfile = await ref.read(storeProfileProvider.future);
      if (!context.mounted) return;

      if (storeProfile == null) {
        TopNotification.show(
          context,
          message: '無法獲取店家資訊，請重新登入',
        );
        isLoading.value = false;
        return;
      }

      final createProductUseCase = ref.read(createProductUseCaseProvider);
      final result = await createProductUseCase(
        formData.toCreateProductParams(
          storeId: storeProfile.id,
          sizes: sizeManager.toCreateProductSizeParams(),
        ),
      );

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        ref.invalidate(productsProvider);
        Navigator.pop(context, true);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('新增商品')),
      body: ProductFormLayout(
        mode: ProductFormMode.create,
        formData: formData,
        sizeManager: sizeManager,
        isLoading: isLoading.value,
        onSubmit: addProduct,
        productCategoryTreeAsync: productCategoryTreeAsync,
        onRetryCategories: () => refreshProductCategories(ref),
        onPickImage: (final remainingCount) async {
          return ImagePickerHelper.pickImages(context, maxImages: remainingCount);
        },
      ),
    );
  }
}
