# Refactor Update Use Cases Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor `UpdateProduct`, `UpdateStoreProfile`, and `UpdateUserProfile` use cases to fetch the original entity internally, allowing the UI to pass only ID and Payload.

**Architecture:** Align with Clean Architecture by moving state fetching from the UI to the Domain Layer (UseCase). The UseCase becomes an orchestrator that fetches the `original` entity, applies changes to create a `target` entity, and passes both to the Repository for persistence and infrastructure tasks (image diffing).

**Tech Stack:** Flutter, Dart, Clean Architecture, Repository Pattern, `typed_result`.

---

### Task 1: Add `getProduct` to `ProductRepository`

**Files:**
- Modify: `lib/feature/store/products/domain/repositories/product_repository.dart`
- Modify: `lib/feature/store/products/data/repositories/product_repository_impl.dart`
- Test: `test/feature/store/products/data/repositories/product_repository_impl_test.dart`

**Step 1: Write the failing test**

```dart
test('should return Product when getProduct is called with valid id', () async {
  // arrange
  when(mockRemoteDataSource.getProduct(tProductId))
      .thenAnswer((_) async => tProductModel);
  // act
  final result = await repository.getProduct(tProductId);
  // assert
  expect(result, Ok(tProduct));
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/feature/store/products/data/repositories/product_repository_impl_test.dart`
Expected: FAIL (Method not defined)

**Step 3: Write minimal implementation**

In `ProductRepository`:
```dart
Future<Result<Product, Failure>> getProduct(String id);
```

In `ProductRepositoryImpl`:
```dart
@override
Future<Result<Product, Failure>> getProduct(String id) async {
  try {
    final model = await _remoteDataSource.getProduct(id);
    return Ok(_mappr.convert<ProductModel, Product>(model));
  } catch (e) {
    return Err(mapExceptionToFailure(e));
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/feature/store/products/data/repositories/product_repository_impl_test.dart`
Expected: PASS

**Step 5: Wait for human review and commit**

Report changes made:
- Modified files: `product_repository.dart`, `product_repository_impl.dart`
- Suggested commit message: `feat: add getProduct to ProductRepository`

---

### Task 2: Refactor `UpdateProduct` UseCase

**Files:**
- Modify: `lib/feature/store/products/domain/usecases/update_product.dart`
- Test: `test/feature/store/products/domain/usecases/update_product_test.dart`

**Step 1: Define `UpdateProductParams` and update `UpdateProduct` signature**

```dart
class UpdateProductParams {
  const UpdateProductParams({
    required this.productId,
    required this.name,
    required this.price,
    required this.finalImageOrder,
    // ... other fields from update_product.dart
  });
  final String productId;
  final String name;
  final double price;
  final List<ImageItem> finalImageOrder;
  // ...
}
```

**Step 2: Implement Orchestration Logic in UseCase**

```dart
Future<Result<void, Failure>> call(UpdateProductParams params) async {
  final originalResult = await _repository.getProduct(params.productId);
  if (originalResult.isErr()) return Err(originalResult.asErr);
  final original = originalResult.asOk;

  final target = original.copyWith(
    name: params.name,
    price: params.price,
    // ... apply other changes
  );

  return _repository.updateProduct(
    original: original,
    target: target,
    finalImageOrder: params.finalImageOrder,
    // ... size params
  );
}
```

**Step 3: Update Repository Interface and Implementation**

Modify `updateProduct` in `ProductRepository` to accept `target` instead of individual fields.

**Step 4: Run tests and verify**

Run: `flutter test test/feature/store/products/domain/usecases/update_product_test.dart`

**Step 5: Wait for human review and commit**

---

### Task 3: Refactor `UpdateStoreProfile` and `UpdateUserProfile`

Follow the same pattern as Task 1 & 2 for:
1. `StoreProfileRepository`: Add `getStoreProfile(String id)`.
2. `UpdateStoreProfile`: Refactor to accept `UpdateStoreProfileParams(id, ...)` and fetch original.
3. `UserProfileRepository`: Add `getUserProfile(String id)`.
4. `UpdateUserProfile`: Refactor to accept `UpdateUserProfileParams(id, ...)` and fetch original.

**Step 5: Wait for human review and commit**

---

### Task 4: Update UI Calling Sites

**Files:**
- Modify: `lib/feature/store/products/presentation/screens/edit_product_screen.dart` (and others)

**Step 1: Update Bloc/Notifier to pass ID + Payload**

Ensure the UI no longer passes the `original` entity to the UseCase.

**Step 2: Verify App Functionality**

Manual verification of product and profile updates.

**Step 3: Final commit and cleanup**
