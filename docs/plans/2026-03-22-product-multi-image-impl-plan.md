# Product Multi-Image Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor the existing single product image upload logic to support up to 3 images, updating the database schema, data models, repository, and UI.

**Architecture:** 
1. The Supabase DB will transition from `image_path TEXT` to `image_paths TEXT[]`.
2. The domain and data models will handle a `List<String>` of paths.
3. The upload logic will be converted to a batch upload using `Future.wait`.
4. The frontend will adapt forms and detail pages to handle multiple images.

**Tech Stack:** Dart, Flutter, Freezed, JsonSerializable, Supabase Storage, AutoMappr.

---

### Task 1: Update Domain Entity and Data Models

**Files:**
- Modify: `lib/feature/store/products/domain/entities/product.dart`
- Modify: `lib/feature/store/products/data/models/product_model.dart`
- Modify: `lib/feature/store/products/data/collections/product_collection.dart`

**Step 1: Modify Domain Entity**
Change `imagePath` and `imageUrl` to `List<String> imagePaths` and `List<String> imageUrls` in `Product`.

**Step 2: Modify Data Model**
Update `ProductModel` to use `@JsonKey(name: 'image_paths') final List<String> imagePaths;` and `final List<String> imageUrls;`. Keep `@JsonKey(includeToJson: false)` on `imageUrls`.

**Step 3: Modify Local Collection**
Update `ProductCollection` to use `late List<String> imagePaths;` and `late List<String> imageUrls;`.

**Step 4: Run Code Generation**
Run `dart run build_runner build -d` to regenerate the `freezed` and `json_serializable` files.

**Step 5: Wait for human review and commit**
Report changes made. Suggested commit message: `refactor(domain): update Product models for multi-image support`

---

### Task 2: Update Data Source and Repository Upload Logic

**Files:**
- Modify: `lib/feature/store/products/data/datasources/product_remote_datasource.dart`
- Modify: `lib/feature/store/products/data/repositories/product_repository_impl.dart`
- Modify: `lib/feature/store/products/domain/usecases/create_product.dart`
- Modify: `lib/feature/store/products/domain/usecases/update_product.dart`

**Step 1: Update Remote Datasource**
Rename `uploadProductImage` to `uploadProductImages`.
Change signature to accept `List<File> images`.
Implement `Future.wait` to upload all images concurrently and return `List<String>` of paths.
Update `_getProductImageUrl` to `_getProductImageUrls` returning a list.

**Step 2: Update Repository**
In `ProductRepositoryImpl`, update `createProduct` and `updateProduct` to pass `List<File> images` to the new datasource method.

**Step 3: Update Use Cases (Params)**
Change `CreateProductParams` and `UpdateProductParams` to accept `List<File> images` instead of `File image`. Add validation to ensure `images.length <= 3`.

**Step 4: Wait for human review and commit**
Report changes made. Suggested commit message: `refactor(data): implement multi-image concurrent upload logic`

---

### Task 3: Update Store UI (Product Form)

**Files:**
- Modify: `lib/feature/store/products/presentation/widgets/product_form_layout.dart`
- Modify: `lib/feature/store/products/presentation/pages/product_create_page.dart` (or wherever the form is used)

**Step 1: Update State/Controller**
Update the form controller/state to hold a `List<File>` instead of a single `File`.

**Step 2: Update Image Picker Widget**
Modify the image selection area to allow picking multiple images. Show a grid/row of selected images. Add a button to add more images up to a maximum of 3.

**Step 3: Wait for human review and commit**
Report changes made. Suggested commit message: `feat(store): add multi-image picker to product form`

---

### Task 4: Update Personal UI (Product Detail & Cards)

**Files:**
- Modify: `lib/feature/personal/shop/presentation/pages/product_detail_page.dart`
- Modify: `lib/feature/personal/shop/presentation/widgets/product_header.dart`
- Modify: `lib/feature/personal/shop/presentation/widgets/product_card.dart`
- Modify: `lib/feature/store/products/presentation/widgets/product_card.dart`

**Step 1: Update Product Cards**
In any `ProductCard` widget, change the image source from `product.imageUrl` to `product.imageUrls.firstOrNull ?? ''` or equivalent safe fallback.

**Step 2: Update Product Detail Header**
In the product detail page (e.g., `ProductHeader`), replace the single image view with a Carousel or PageView to allow swiping through `product.imageUrls`. Add dot indicators if there are multiple images.

**Step 3: Wait for human review and commit**
Report changes made. Suggested commit message: `feat(ui): display multiple product images in carousel`