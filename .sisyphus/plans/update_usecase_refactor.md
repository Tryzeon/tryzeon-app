# Update UseCase Refactoring Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor `UpdateProduct`, `UpdateStoreProfile`, and `UpdateUserProfile` UseCases to handle partial updates cleanly by fetching current state first, ensuring the Repository can perform infrastructure-level diffing (especially for images).

**Architecture:** UseCase fetches the current entity state via `getRepository(id)` and passes both `(original, target)` to the Repository. The Repository handles comparison and triggers image uploads/deletions.

**Tech Stack:** Dart, Flutter, typed_result (Result types), Freezed (Entities).

---

## 1. Executive Summary

### Current State
*   `ProductRepository` lacks a single-entity fetch method (`getProduct(String id)`).
*   UseCases often take large parameter objects and pass them directly to repos without context of the current state.
*   Infrastructure layer lacks the "old" state needed to optimize cloud storage (e.g., deleting old images).

### Target State
*   **Prerequisite Methods:** All repositories support fetching a single entity by ID.
*   **Contextual Updates:** `Repo.update(original: entity, target: entity)` pattern across all feature sets.
*   **Clean Infrastructure:** Repositories encapsulate image diffing logic. If `original.image != target.image`, the repo handles the storage cleanup.

---

## 2. Scope of Refactoring

Targeted files (using correct `lib/feature/` paths):
1.  `lib/feature/store/products/domain/usecases/update_product.dart`
2.  `lib/feature/store/profile/domain/usecases/update_store_profile.dart`
3.  `lib/feature/personal/profile/domain/usecases/update_user_profile.dart`

Related Repositories (Interfaces and Implementations) in:
*   `lib/feature/store/products/`
*   `lib/feature/store/profile/`
*   `lib/feature/personal/profile/`

---

## 3. Implementation Plan

### Task 1: Implement ProductRepository.getProduct()

**Files:**
- Modify: `lib/feature/store/products/domain/repositories/product_repository.dart`
- Modify: `lib/feature/store/products/data/repositories/product_repository_impl.dart`
- Modify: `lib/feature/store/products/data/datasources/product_remote_data_source.dart`

**Step 1: Update Remote Data Source**
Add `Future<ProductModel> getProduct(String id)` to the interface and implementation. Ensure it fetches the single product from the backend.

**Step 2: Update Repository Interface**
Add `Future<Result<Product, Failure>> getProduct(String id)` to `ProductRepository`.

**Step 3: Update Repository Implementation**
Implement `getProduct` by calling the data source and mapping to the domain entity.

**Step 4: Wait for human review and commit**
Suggested commit message: `feat(product): add getProduct method to repository`

---

### Task 2: Refactor Product Update UseCase

**Files:**
- Modify: `lib/feature/store/products/domain/usecases/update_product.dart`
- Modify: `lib/feature/store/products/domain/repositories/product_repository.dart`
- Modify: `lib/feature/store/products/data/repositories/product_repository_impl.dart`

**Step 1: Update Repository Update Signature**
Change `updateProduct` in `ProductRepository` and `ProductRepositoryImpl` to accept `original` and `target` products if not already aligned.

**Step 2: Update UseCase Implementation**
Refactor the UseCase to:
1.  Fetch `originalProduct` using `_repo.getProduct(id)`.
2.  Construct `targetProduct` using `originalProduct.copyWith(...)`.
3.  Call `_repo.updateProduct(original: originalProduct, target: targetProduct)`.

**Step 3: Update Repository Implementation (Diffing)**
Update `ProductRepositoryImpl.updateProduct` to compare images between `original` and `target`, handling storage cleanup.

**Step 4: Wait for human review and commit**
Suggested commit message: `refactor(product): update usecase to fetch current state before update`

---

### Task 3: Refactor Store Profile Update UseCase

**Files:**
- Modify: `lib/feature/store/profile/domain/usecases/update_store_profile.dart`
- Modify: `lib/feature/store/profile/data/repositories/store_profile_repository_impl.dart`

**Step 1: Verify getStoreProfile**
Ensure `StoreProfileRepository.getStoreProfile()` returns the current state correctly.

**Step 2: Update UseCase Implementation**
Refactor to fetch `getStoreProfile()` first, then build the target profile and pass both to `updateStoreProfile`.

**Step 3: Update Repository Implementation (Diffing)**
Ensure `StoreProfileRepositoryImpl.updateStoreProfile` uses the `original` profile to identify logo changes and delete old files from storage.

**Step 4: Wait for human review and commit**
Suggested commit message: `refactor(store): update store profile usecase to fetch current state`

---

### Task 4: Refactor User Profile Update UseCase

**Files:**
- Modify: `lib/feature/personal/profile/domain/usecases/update_user_profile.dart`
- Modify: `lib/feature/personal/profile/data/repositories/user_profile_repository_impl.dart`

**Step 1: Verify getUserProfile**
Ensure `UserProfileRepository.getUserProfile()` is available and functional.

**Step 2: Update UseCase Implementation**
Refactor to fetch `getUserProfile()` first, construct the target profile, and pass both to `updateUserProfile`.

**Step 3: Update Repository Implementation (Diffing)**
Ensure `UserProfileRepositoryImpl.updateUserProfile` handles avatar cleanup by comparing `original` and `target`.

**Step 4: Wait for human review and commit**
Suggested commit message: `refactor(user): update user profile usecase to fetch current state`
