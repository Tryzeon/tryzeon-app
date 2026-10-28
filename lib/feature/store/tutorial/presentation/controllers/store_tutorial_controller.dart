import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_finished_provider.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_state.dart';

part 'store_tutorial_controller.g.dart';

/// Listens instead of watching: a products reload mid-tour must not rebuild
/// the controller and drop the step the brand is on. A save is reported by the
/// page rather than read off the list, which may reload instead of merging.
@riverpod
class StoreTutorialController extends _$StoreTutorialController {
  var _persisted = false;

  @override
  StoreTutorialState build() {
    _persisted = false;

    ref.listen(productsProvider, (final _, final next) {
      state = _baseline(products: next);
    });
    ref.listen(storeTutorialFinishedProvider, (final _, final next) {
      state = _baseline(finished: next);
    });

    return _baseline(current: const StoreTutorialState.inactive());
  }

  void enterAddProduct() {
    if (state is StoreTutorialAddProduct) {
      state = const StoreTutorialState.pickImage();
    }
  }

  /// Runs after the add page unmounts, which may outlive this controller when
  /// the whole store shell is torn down.
  void leaveAddProduct() {
    if (!ref.mounted) return;
    if (state.isFormStep) state = const StoreTutorialState.addProduct();
  }

  void mainImagePicked() {
    if (state is StoreTutorialPickImage) {
      state = const StoreTutorialState.analyzing();
    }
  }

  void mainImageRemoved() {
    if (state is StoreTutorialAnalyzing) {
      state = const StoreTutorialState.pickImage();
    }
  }

  /// A failed analysis moves on too: its indicator is gone, so staying would
  /// leave the brand with no hint and no way to skip.
  void imageAnalysisFinished() {
    if (state is StoreTutorialPickImage || state is StoreTutorialAnalyzing) {
      state = const StoreTutorialState.reviewInfo();
    }
  }

  /// Persists right away, like the personal tour's first try-on, so a brand
  /// who leaves during the last steps never sees the tour again; those steps
  /// only live in this session.
  void productCreated(final ProductStatus status) {
    if (!state.isFormStep) return;
    state = StoreTutorialState.reviewProduct(status: status);
    unawaited(_persist());
  }

  void next() {
    state = switch (state) {
      StoreTutorialReviewInfo() => const StoreTutorialState.price(),
      StoreTutorialPrice() => const StoreTutorialState.purchaseLink(),
      StoreTutorialPurchaseLink() => const StoreTutorialState.sizes(),
      StoreTutorialSizes() => const StoreTutorialState.publish(),
      StoreTutorialPublish() => const StoreTutorialState.save(),
      StoreTutorialReviewProduct() => const StoreTutorialState.openAccount(),
      final current => current,
    };
  }

  void accountTabOpened() {
    if (state is StoreTutorialOpenAccount) {
      state = const StoreTutorialState.viewPerformance();
    }
  }

  Future<void> finish() async {
    state = const StoreTutorialState.inactive();
    await _persist();
  }

  Future<void> _persist() async {
    if (_persisted) return;
    _persisted = true;
    await ref.read(storeTutorialFinishedProvider.notifier).finish();
  }

  StoreTutorialState _baseline({
    final AsyncValue<List<Product>>? products,
    final AsyncValue<bool>? finished,
    final StoreTutorialState? current,
  }) {
    final AsyncValue<List<Product>> productsAsync =
        products ?? ref.read(productsProvider);
    final AsyncValue<bool> finishedAsync =
        finished ?? ref.read(storeTutorialFinishedProvider);
    final step = current ?? state;

    if (!productsAsync.hasValue || productsAsync.hasError) {
      return const StoreTutorialState.inactive();
    }
    // The save already persisted the finish, so the last steps outlive it.
    if (step is StoreTutorialReviewProduct ||
        step is StoreTutorialOpenAccount ||
        step is StoreTutorialViewPerformance) {
      return step;
    }
    if (finishedAsync.value != false) {
      return const StoreTutorialState.inactive();
    }
    // A save merges the new product into the list before the page reports it,
    // so a form step outlives a non-empty list until productCreated() runs.
    if (step.isFormStep) return step;
    if (productsAsync.requireValue.isNotEmpty) {
      return const StoreTutorialState.inactive();
    }
    return const StoreTutorialState.addProduct();
  }
}
