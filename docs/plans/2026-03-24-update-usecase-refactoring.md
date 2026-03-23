# Refactoring Plan: Clean Architecture Update Use Cases

## 1. Executive Summary
**Current State:** The UI is responsible for providing the `original` entity to the Update UseCase. This couples the UI to the persistence state and forces it to manage data that should be encapsulated within the domain/data layers.
**Target State:** The UI passes only the `id` of the entity and a `payload` of changes. The UseCase fetches the `original` entity from the Repository, applies domain logic (e.g., `copyWith`), and passes the state transition (`original` vs `target`) to the Repository for persistence and infrastructure tasks (like image diffing).

## 2. Scope of Refactoring
- **Use Cases:** `UpdateProduct`, `UpdateStoreProfile`, `UpdateUserProfile`.
- **Repositories:** `ProductRepository`, `StoreProfileRepository`, `UserProfileRepository` (and implementations).
- **UI:** Product Edit Screen, Store Profile Edit Screen, User Profile Edit Screen.

## 3. Step-by-step Implementation Guide

### UseCase Refactoring (Example: UpdateProduct)

**Before:**
```dart
Future<Result<void, Failure>> call({
  required final Product original,
  required final List<ImageItem> finalImageOrder,
  // ... many individual fields
}) => _repository.updateProduct(original: original, ...);
```

**After:**
```dart
class UpdateProductParams {
  final String productId;
  final String name;
  final double price;
  final List<ImageItem> finalImageOrder;
  // ... other payload fields
}

class UpdateProduct {
  Future<Result<void, Failure>> call(UpdateProductParams params) async {
    // 1. Fetch original state
    final originalResult = await _repository.getProduct(params.productId);
    if (originalResult.isErr()) return Err(originalResult.asErr);
    final original = originalResult.asOk;

    // 2. Create target state (Domain Logic)
    final target = original.copyWith(
      name: params.name,
      price: params.price,
      // imagePaths handled by repo during upload
    );

    // 3. Persist
    return _repository.updateProduct(
      original: original,
      target: target,
      finalImageOrder: params.finalImageOrder,
      // ... size params
    );
  }
}
```

### UI Calling Side

**Before:**
```dart
updateProduct(
  original: currentProduct, // UI forced to keep 'original'
  name: nameController.text,
  // ...
);
```

**After:**
```dart
updateProduct(
  UpdateProductParams(
    productId: currentProduct.id, // ID only
    name: nameController.text,
    // ...
  ),
);
```

## 4. Handling Infrastructure Edge Cases (Image Diffing)
To maintain clean boundaries while handling complex infrastructure logic (like deleting old images from storage), the UseCase passes both the `original` and `target` entities to the Repository.

**Pragmatic Approach:**
1. **UseCase** fetches `original`.
2. **Repository.updateProduct** receives `original` and `target`.
3. **Repository Implementation** compares `original.imagePaths` with the newly uploaded paths (derived from `finalImageOrder`) to calculate which files to delete from the remote storage.

## 5. Risks & Mitigations
- **Risk:** Redundant DB calls (fetching entity twice).
  - **Mitigation:** Use Repository-level caching (Local Data Source) to ensure the second fetch is near-instant.
- **Risk:** Complex Repository Signatures.
  - **Mitigation:** Use Parameter Objects (e.g., `UpdateProductParams`) to keep method signatures manageable.
- **Risk:** Breaking existing UI logic.
  - **Mitigation:** Refactor one UseCase at a time, ensuring unit tests pass for both UseCase and Repository.
