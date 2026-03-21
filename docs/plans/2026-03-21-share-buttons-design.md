# Design Document: Share Buttons for Product and Store Pages

- **Date**: 2026-03-21
- **Status**: Draft
- **Author**: Sisyphus-Junior

## 1. Overview
Adding a "Share" feature to the Product Detail Page and Store Page to allow users to easily share content with others via a native share dialog.

## 2. Requirements
- Add a share button (IconButton with `Icons.share`) to the `AppBar` actions.
- Use the `share_plus` package for triggering the native share dialog.
- Construct the share text in the format: "Name\nURL".

## 3. Design Details

### 3.1 Product Detail Page
- **File**: `lib/feature/personal/shop/presentation/pages/product_detail_page.dart`
- **Logic**:
  - Check if `productAsync.hasValue`.
  - On press: `Share.share('${product.name}\nhttps://tryzeon.com/product/${product.id}')`.
- **UI**: Added to `AppBar.actions`.

### 3.2 Store Page
- **File**: `lib/feature/personal/shop/presentation/pages/store_page.dart`
- **Logic**:
  - Check if `storeInfoAsync.hasValue`.
  - On press: `Share.share('${storeInfo.name}\nhttps://tryzeon.com/store/${storeInfo.id}')`.
- **UI**: Added to `AppBar.actions`.

## 4. Implementation Plan (Summary)
1. Import `share_plus` in both files.
2. Update `ProductDetailPage` to include the share button in `AppBar.actions`.
3. Update `StorePage` to include the share button in `AppBar.actions`.
4. Verify the share content format on both pages.

## 5. Testing
- Verify that the share button only appears when the data is loaded.
- Verify the content of the shared text for both products and stores.
