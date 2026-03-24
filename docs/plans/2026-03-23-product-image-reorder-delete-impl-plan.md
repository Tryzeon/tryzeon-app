# Product Image Reorder & Delete Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement unified image management supporting reorder, delete existing images, and upload new images with proper state tracking.

**Architecture:**
1. Introduce `ImageItem` sealed class to unify existing (URL) and new (File) images in a single ordered list
2. UI uses `ReorderableListView` for drag-and-drop reordering
3. Repository receives final ordered `List<ImageItem>`, handles upload/delete via diff with original

**Tech Stack:** Dart, Flutter, Freezed, ReorderableListView, Supabase Storage

---

### Task 1: Create ImageItem Freezed Union Type

**Files:**
- Create: `lib/feature/store/products/domain/value_objects/image_item.dart`

**Step 1: Create the Freezed union type file**

```dart
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_item.freezed.dart';

/// Unified representation of product images in the editing flow.
/// Uses Freezed union types for type-safe pattern matching.
@freezed
sealed class ImageItem with _$ImageItem {
  /// An image that already exists in Supabase storage.
  const factory ImageItem.existing({
    /// Storage path (e.g., "products/abc123/image1.jpg")
    required String path,

    /// Public URL for display
    required String url,
  }) = ExistingImageItem;

  /// A new image selected by the user, pending upload.
  const factory ImageItem.newImage({
    required File file,
  }) = NewImageItem;
}
```

**Step 2: Run build_runner to generate Freezed code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `image_item.freezed.dart` generated successfully

**Step 3: Verify file compiles**

Run: `dart analyze lib/feature/store/products/domain/value_objects/image_item.dart`
Expected: No issues found

**Step 4: Wait for human review and commit**

Report changes made. Suggested commit message: `feat(domain): add ImageItem Freezed union type for unified image handling`

---

### Task 2: Update ProductFormData to Use ImageItem List

**Files:**
- Modify: `lib/feature/store/products/presentation/hooks/use_product_form.dart`

**Step 1: Add import and update ProductFormData class**

Add import at top:
```dart
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
```

Replace `selectedImages` field with `images`:
```dart
class ProductFormData {
  ProductFormData({
    required this.formKey,
    required this.nameController,
    required this.priceController,
    required this.purchaseLinkController,
    required this.materialController,
    required this.images, // Changed from selectedImages
    required this.selectedCategoryIds,
    required this.selectedElasticity,
    required this.selectedFit,
    required this.selectedStyles,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchaseLinkController;
  final TextEditingController materialController;
  final ValueNotifier<List<ImageItem>> images; // Changed type
  final ValueNotifier<Set<String>> selectedCategoryIds;
  final ValueNotifier<ProductElasticity?> selectedElasticity;
  final ValueNotifier<ProductFit?> selectedFit;
  final ValueNotifier<List<ClothingStyle>?> selectedStyles;

  bool validate(final BuildContext context) {
    return formKey.currentState?.validate() ?? false;
  }

  /// Extract only new images (files pending upload)
  List<File> get newImageFiles =>
      images.value.whereType<NewImageItem>().map((e) => e.file).toList();

  /// Extract kept existing image paths in current order
  List<String> get keptExistingPaths =>
      images.value.whereType<ExistingImageItem>().map((e) => e.path).toList();

  CreateProductParams toCreateProductParams({
    required final String storeId,
    required final List<CreateProductSizeParams>? sizes,
  }) {
    return CreateProductParams(
      storeId: storeId,
      name: nameController.text,
      categoryIds: selectedCategoryIds.value.toList(),
      price: double.tryParse(priceController.text) ?? 0.0,
      images: newImageFiles, // Use extracted files
      purchaseLink: purchaseLinkController.text.isNotEmpty
          ? purchaseLinkController.text
          : null,
      material: materialController.text.isNotEmpty ? materialController.text : null,
      elasticity: selectedElasticity.value,
      fit: selectedFit.value,
      styles: selectedStyles.value,
      sizes: sizes,
    );
  }

  Product toProduct({
    required final String id,
    required final String storeId,
    required final List<String> imagePaths,
    required final List<String> imageUrls,
    required final List<ProductSize>? sizes,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) {
    return Product(
      storeId: storeId,
      name: nameController.text,
      categoryIds: selectedCategoryIds.value.toList(),
      price: double.tryParse(priceController.text) ?? 0.0,
      purchaseLink: purchaseLinkController.text,
      material: materialController.text,
      elasticity: selectedElasticity.value,
      fit: selectedFit.value,
      styles: selectedStyles.value,
      imagePaths: imagePaths,
      imageUrls: imageUrls,
      id: id,
      sizes: sizes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
```

**Step 2: Update useProductForm hook**

```dart
ProductFormData useProductForm({final Product? initialProduct}) {
  final formKey = useMemoized(GlobalKey<FormState>.new);
  final nameController = useTextEditingController(text: initialProduct?.name);
  final priceController = useTextEditingController(
    text: initialProduct?.price.toString(),
  );
  final purchaseLinkController = useTextEditingController(
    text: initialProduct?.purchaseLink,
  );
  final materialController = useTextEditingController(text: initialProduct?.material);

  // Initialize with existing images if editing, empty list if creating
  final initialImages = useMemoized(() {
    if (initialProduct == null) return <ImageItem>[];
    final paths = initialProduct.imagePaths;
    final urls = initialProduct.imageUrls;
    return List.generate(
      paths.length,
      (i) => ImageItem.existing(
        path: paths[i],
        url: i < urls.length ? urls[i] : '',
      ),
    );
  });

  final images = useState<List<ImageItem>>(initialImages);

  final selectedCategoryIds = useValueNotifier<Set<String>>(
    initialProduct?.categoryIds.toSet() ?? {},
  );
  final selectedElasticity = useValueNotifier<ProductElasticity?>(
    initialProduct?.elasticity,
  );
  final selectedFit = useValueNotifier<ProductFit?>(initialProduct?.fit);
  final selectedStyles = useValueNotifier<List<ClothingStyle>?>(initialProduct?.styles);

  return ProductFormData(
    formKey: formKey,
    nameController: nameController,
    priceController: priceController,
    purchaseLinkController: purchaseLinkController,
    materialController: materialController,
    images: images,
    selectedCategoryIds: selectedCategoryIds,
    selectedElasticity: selectedElasticity,
    selectedFit: selectedFit,
    selectedStyles: selectedStyles,
  );
}
```

**Step 3: Verify file compiles**

Run: `dart analyze lib/feature/store/products/presentation/hooks/use_product_form.dart`
Expected: No issues (may have downstream errors in other files, which we'll fix next)

**Step 4: Wait for human review and commit**

Report changes made. Suggested commit message: `refactor(form): update ProductFormData to use unified ImageItem list`

---

### Task 3: Update ProductImageEditor with ReorderableListView

**Files:**
- Modify: `lib/feature/store/products/presentation/widgets/product_image_editor.dart`

**Step 1: Replace entire file with reorderable implementation**

```dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';

class ProductImageEditor extends StatelessWidget {
  const ProductImageEditor({
    super.key,
    required this.images,
    required this.onImagesChanged,
    required this.onPickImage,
    this.maxImages = 3,
  });

  final List<ImageItem> images;
  final ValueChanged<List<ImageItem>> onImagesChanged;
  final VoidCallback onPickImage;
  final int maxImages;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canAddMore = images.length < maxImages;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('商品圖片', style: textTheme.titleSmall),
              Text(
                '${images.length}/$maxImages',
                style: textTheme.bodySmall?.copyWith(
                  color: images.length >= maxImages
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '長按拖曳可調整順序',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (images.isEmpty)
            GestureDetector(
              onTap: onPickImage,
              child: _buildAddImagePlaceholder(context, colorScheme, textTheme),
            )
          else
            SizedBox(
              height: 120,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                itemCount: images.length + (canAddMore ? 1 : 0),
                onReorder: (oldIndex, newIndex) {
                  // Ignore reordering involving the "add" button
                  if (oldIndex >= images.length || newIndex > images.length) {
                    return;
                  }
                  final updated = List<ImageItem>.from(images);
                  final item = updated.removeAt(oldIndex);
                  final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
                  updated.insert(insertIndex, item);
                  onImagesChanged(updated);
                },
                itemBuilder: (context, index) {
                  // "Add" button at the end
                  if (index == images.length) {
                    return Padding(
                      key: const ValueKey('add_button'),
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: onPickImage,
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 32,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final item = images[index];
                  return ReorderableDragStartListener(
                    key: ValueKey(item),
                    index: index,
                    child: _buildImageCard(
                      context,
                      colorScheme,
                      item: item,
                      index: index,
                      onRemove: () {
                        final updated = List<ImageItem>.from(images)..removeAt(index);
                        onImagesChanged(updated);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard(
    final BuildContext context,
    final ColorScheme colorScheme, {
    required final ImageItem item,
    required final int index,
    required final VoidCallback onRemove,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: switch (item) {
              ExistingImageItem(:final url, :final path) => CachedNetworkImage(
                  imageUrl: url,
                  cacheKey: path,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.outline,
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              NewImageItem(:final file) => Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
            },
          ),
          // Order indicator
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImagePlaceholder(
    final BuildContext context,
    final ColorScheme colorScheme,
    final TextTheme textTheme,
  ) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 40, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text('點擊選擇圖片', style: textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Verify file compiles**

Run: `dart analyze lib/feature/store/products/presentation/widgets/product_image_editor.dart`
Expected: No issues found

**Step 3: Wait for human review and commit**

Report changes made. Suggested commit message: `feat(ui): implement reorderable ProductImageEditor with drag-drop support`

---

### Task 4: Update ProductFormLayout to Use New ImageItem API

**Files:**
- Modify: `lib/feature/store/products/presentation/widgets/product_form_layout.dart`

**Step 1: Update imports**

Add at top:
```dart
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
```

**Step 2: Remove existingImageUrls/existingImagePaths props, update widget**

Remove these fields from constructor and class:
- `existingImageUrls`
- `existingImagePaths`

Update the widget class:
```dart
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
    this.onDelete,
    super.key,
  });

  final ProductFormMode mode;
  final ProductFormData formData;
  final ProductSizeManager sizeManager;
  final bool isLoading;
  final VoidCallback onSubmit;
  final Future<List<File>?> Function() onPickImage;
  final dynamic productCategoryTreeAsync;
  final VoidCallback onRetryCategories;
  final VoidCallback? onDelete;
```

**Step 3: Update FormField section in build method**

Replace the FormField<List<File>> with:
```dart
FormField<List<ImageItem>>(
  initialValue: formData.images.value,
  validator: (final value) => _validateImages(value, mode),
  builder: (final state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductImageEditor(
          images: formData.images.value,
          onImagesChanged: (updated) {
            formData.images.value = updated;
            state.didChange(updated);
          },
          onPickImage: () async {
            final files = await onPickImage();
            if (files != null && files.isNotEmpty) {
              final newItems = files.map((f) => ImageItem.newImage(file: f)).toList();
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
```

**Step 4: Add validation helper method**

Add this method to the file (outside the class, or as a static method):
```dart
String? _validateImages(List<ImageItem>? images, ProductFormMode mode) {
  if (mode == ProductFormMode.create && (images == null || images.isEmpty)) {
    return '請至少選擇一張商品圖片';
  }
  return null;
}
```

**Step 5: Remove old validator import if present**

Remove the call to `AppValidators.validateProductImage` since we're using inline validation now.

**Step 6: Verify file compiles**

Run: `dart analyze lib/feature/store/products/presentation/widgets/product_form_layout.dart`
Expected: No issues found

**Step 7: Wait for human review and commit**

Report changes made. Suggested commit message: `refactor(ui): update ProductFormLayout to use ImageItem-based editor`

---

### Task 5: Update ProductDetailPage (Edit Flow)

**Files:**
- Modify: `lib/feature/store/products/presentation/pages/product_detail_page.dart`

**Step 1: Add import**

```dart
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
```

**Step 2: Update updateProduct function**

Replace the existing `updateProduct` function:
```dart
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
```

**Step 3: Update ProductFormLayout call**

Remove `existingImageUrls` and `existingImagePaths` params:
```dart
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
```

**Step 4: Verify file compiles (will have errors until usecase is updated)**

Run: `dart analyze lib/feature/store/products/presentation/pages/product_detail_page.dart`
Expected: Errors related to UpdateProduct usecase signature (will fix in Task 7)

**Step 5: Wait for human review and commit**

Report changes made. Suggested commit message: `refactor(ui): update ProductDetailPage to pass finalImageOrder`

---

### Task 6: Update AddProductPage (Create Flow)

**Files:**
- Modify: `lib/feature/store/products/presentation/pages/add_product_page.dart`

**Step 1: Verify current implementation and update if needed**

The create flow should already work since `ProductFormData.toCreateProductParams()` extracts `newImageFiles` from the images list. Just need to remove old props from ProductFormLayout call if present.

Update the ProductFormLayout call to remove `existingImageUrls` and `existingImagePaths` if they exist (they shouldn't for create mode, but verify).

**Step 2: Verify file compiles**

Run: `dart analyze lib/feature/store/products/presentation/pages/add_product_page.dart`
Expected: No issues found

**Step 3: Wait for human review and commit**

Report changes made. Suggested commit message: `refactor(ui): update AddProductPage for ImageItem compatibility`

---

### Task 7: Update UpdateProduct UseCase Signature

**Files:**
- Modify: `lib/feature/store/products/domain/usecases/update_product.dart`

**Step 1: Add import and update signature**

```dart
import 'dart:io';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:typed_result/typed_result.dart';

class UpdateProduct {
  UpdateProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, Failure>> call({
    required final Product original,
    required final List<ImageItem> finalImageOrder,
    required final List<CreateProductSizeParams> sizesToAdd,
    required final List<ProductSize> sizesToUpdate,
    required final List<String> sizeIdsToDelete,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final List<ClothingStyle>? styles,
  }) => _repository.updateProduct(
    original: original,
    finalImageOrder: finalImageOrder,
    sizesToAdd: sizesToAdd,
    sizesToUpdate: sizesToUpdate,
    sizeIdsToDelete: sizeIdsToDelete,
    name: name,
    categoryIds: categoryIds,
    price: price,
    purchaseLink: purchaseLink,
    material: material,
    elasticity: elasticity,
    fit: fit,
    styles: styles,
  );
}
```

**Step 2: Verify file compiles (will have errors until repository interface is updated)**

Run: `dart analyze lib/feature/store/products/domain/usecases/update_product.dart`
Expected: Errors related to ProductRepository signature (will fix in Task 8)

**Step 3: Wait for human review and commit**

Report changes made. Suggested commit message: `refactor(domain): update UpdateProduct usecase for ImageItem support`

---

### Task 8: Update ProductRepository Interface

**Files:**
- Modify: `lib/feature/store/products/domain/repositories/product_repository.dart`

**Step 1: Add import and update signature**

```dart
import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductRepository {
  Future<Result<List<Product>, Failure>> getProducts({
    required final String storeId,
    final SortCondition sort = SortCondition.defaultSort,
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> createProduct(final CreateProductParams params);

  Future<Result<void, Failure>> updateProduct({
    required final Product original,
    required final List<ImageItem> finalImageOrder,
    required final List<CreateProductSizeParams> sizesToAdd,
    required final List<ProductSize> sizesToUpdate,
    required final List<String> sizeIdsToDelete,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final List<ClothingStyle>? styles,
  });

  Future<Result<void, Failure>> deleteProduct(final Product product);
}
```

**Step 2: Verify file compiles**

Run: `dart analyze lib/feature/store/products/domain/repositories/product_repository.dart`
Expected: No issues found

**Step 3: Wait for human review and commit**

Report changes made. Suggested commit message: `refactor(domain): update ProductRepository interface for ImageItem`

---

### Task 9: Update ProductRepositoryImpl with Image Diff Logic

**Files:**
- Modify: `lib/feature/store/products/data/repositories/product_repository_impl.dart`

**Step 1: Add import**

```dart
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
```

**Step 2: Replace updateProduct method**

```dart
@override
Future<Result<void, Failure>> updateProduct({
  required final Product original,
  required final List<ImageItem> finalImageOrder,
  required final List<CreateProductSizeParams> sizesToAdd,
  required final List<ProductSize> sizesToUpdate,
  required final List<String> sizeIdsToDelete,
  required final String name,
  required final List<String> categoryIds,
  required final double price,
  final String? purchaseLink,
  final String? material,
  final ProductElasticity? elasticity,
  final ProductFit? fit,
  final List<ClothingStyle>? styles,
}) async {
  try {
    // 1. Separate existing paths and new files from final order
    final existingPaths = <String>[];
    final newFiles = <File>[];
    final newFileIndices = <int>[]; // Track positions of new files

    for (int i = 0; i < finalImageOrder.length; i++) {
      final item = finalImageOrder[i];
      switch (item) {
        case ExistingImageItem(:final path):
          existingPaths.add(path);
        case NewImageItem(:final file):
          newFiles.add(file);
          newFileIndices.add(i);
      }
    }

    // 2. Upload new images if any
    List<String> uploadedPaths = [];
    if (newFiles.isNotEmpty) {
      uploadedPaths = await _remoteDataSource.uploadProductImages(
        storeId: original.storeId,
        images: newFiles,
      );

      // Save to local cache
      for (int i = 0; i < newFiles.length; i++) {
        final bytes = await newFiles[i].readAsBytes();
        await _localDataSource.saveProductImage(bytes, uploadedPaths[i]);
      }
    }

    // 3. Build final image paths in correct order
    final finalImagePaths = <String>[];
    int existingIndex = 0;
    int newIndex = 0;

    for (final item in finalImageOrder) {
      switch (item) {
        case ExistingImageItem():
          finalImagePaths.add(existingPaths[existingIndex++]);
        case NewImageItem():
          finalImagePaths.add(uploadedPaths[newIndex++]);
      }
    }

    // 4. Compute removed images via diff
    final removedPaths = original.imagePaths
        .where((p) => !finalImagePaths.contains(p))
        .toList();

    // 5. Build target product
    final targetProduct = original.copyWith(
      name: name,
      categoryIds: categoryIds,
      price: price,
      purchaseLink: purchaseLink,
      material: material,
      elasticity: elasticity,
      fit: fit,
      styles: styles,
      imagePaths: finalImagePaths,
    );

    final productChanged = original != targetProduct;
    final sizesChanged =
        sizesToAdd.isNotEmpty || sizesToUpdate.isNotEmpty || sizeIdsToDelete.isNotEmpty;

    if (!productChanged && !sizesChanged) {
      return const Ok(null);
    }

    // 6. Update product in DB
    if (productChanged) {
      final targetModel = _mappr.convert<Product, ProductModel>(targetProduct);
      await _remoteDataSource.updateProduct(targetModel);
    }

    // 7. Delete removed images (fire-and-forget)
    if (removedPaths.isNotEmpty) {
      _remoteDataSource.deleteProductImages(removedPaths).ignore();
      _localDataSource.deleteProductImages(removedPaths).ignore();
    }

    // 8. Handle size changes
    if (sizesChanged) {
      // Delete removed sizes
      for (final sizeId in sizeIdsToDelete) {
        await _remoteDataSource.deleteProductSize(sizeId);
      }

      // Add new sizes
      for (final sizeParams in sizesToAdd) {
        final sizeRequest = CreateProductSizeRequest(
          productId: original.id,
          name: sizeParams.name,
          measurements: sizeParams.measurements != null
              ? const MeasurementsMappr().convert<Measurements, MeasurementsModel>(
                  sizeParams.measurements!,
                )
              : null,
        );
        await _remoteDataSource.insertProductSize(sizeRequest);
      }

      // Update existing sizes
      for (final size in sizesToUpdate) {
        final sizeModel = _mappr.convert<ProductSize, ProductSizeModel>(size);
        await _remoteDataSource.updateProductSize(sizeModel);
      }
    }

    // 9. Update local cache
    final model = await _remoteDataSource.getProduct(original.id);

    final currentCache =
        await _localDataSource.getProducts(sort: SortCondition.defaultSort) ?? [];
    await _localDataSource.saveProducts(
      currentCache.map((final p) => p.id == model.id ? model : p).toList(),
    );

    return const Ok(null);
  } catch (e, stackTrace) {
    AppLogger.error('Fail to update product', e, stackTrace);
    return Err(mapExceptionToFailure(e));
  }
}
```

**Step 3: Verify file compiles**

Run: `dart analyze lib/feature/store/products/data/repositories/product_repository_impl.dart`
Expected: No issues found

**Step 4: Wait for human review and commit**

Report changes made. Suggested commit message: `feat(data): implement image reorder/delete logic in ProductRepositoryImpl`

---

### Task 10: Run Full Analysis and Fix Remaining Issues

**Step 1: Run full project analysis**

Run: `dart analyze lib/`
Expected: No issues found (or only pre-existing issues)

**Step 2: Run build_runner to regenerate any affected code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Success

**Step 3: Wait for human review and commit**

Report any fixes made. Suggested commit message: `chore: fix remaining issues after image reorder implementation`

---

### Task 11: Manual Testing Checklist

**Test Scenarios:**

1. **Create product with multiple images**
   - Pick 3 images → verify order displayed correctly
   - Reorder images via drag → verify new order persisted
   - Remove middle image → verify remaining images shift correctly
   - Submit → verify DB has correct image_paths order

2. **Edit product - reorder existing images**
   - Open existing product with 3 images
   - Drag image 3 to position 1
   - Submit → verify DB order changed, no images deleted

3. **Edit product - delete existing image**
   - Open existing product with 3 images
   - Delete image 2
   - Submit → verify image removed from DB and storage

4. **Edit product - add new + reorder + delete**
   - Open existing product with 2 images
   - Add 1 new image
   - Reorder: new image to position 1
   - Delete original image 2
   - Submit → verify:
     - New image uploaded and at position 1
     - Remaining original at position 2
     - Deleted original removed from storage

5. **Edit product - no changes**
   - Open existing product
   - Make no changes
   - Submit → verify no unnecessary API calls

**Step: Wait for human to complete manual testing**

Report test results. Suggested commit message: `test: verify image reorder/delete functionality`
