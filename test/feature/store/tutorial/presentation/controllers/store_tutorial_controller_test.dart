import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/controllers/store_tutorial_controller.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_finished_provider.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_state.dart';

import '../../../../../support/store_test_doubles.dart';

class _Products extends ProductsNotifier {
  _Products(this._initial);

  final List<Product> _initial;
  Completer<void>? _reload;

  @override
  Future<List<Product>> build() async {
    await _reload?.future;
    return _initial;
  }

  void emit(final List<Product> products) => state = AsyncData(products);

  void emitError() =>
      state = const AsyncError(UnknownFailure('boom'), StackTrace.empty);

  void startReload() {
    _reload = Completer();
    ref.invalidateSelf();
  }
}

class _Finished extends StoreTutorialFinishedNotifier {
  _Finished({required this.finished});

  final bool finished;
  var finishes = 0;

  @override
  Future<bool> build() async => finished;

  @override
  Future<void> finish() async {
    finishes++;
    state = const AsyncData(true);
  }
}

void main() {
  late ProviderContainer container;
  late _Products products;
  late _Finished finished;

  Future<StoreTutorialController> start({
    final List<Product> initial = const [],
    final bool isFinished = false,
  }) async {
    products = _Products(initial);
    finished = _Finished(finished: isFinished);
    container = ProviderContainer(
      overrides: [
        storeProfileProvider.overrideWith(
          () => FakeStoreProfile(() async => storeProfile()),
        ),
        productsProvider.overrideWith(() => products),
        storeTutorialFinishedProvider.overrideWith(() => finished),
      ],
    );
    addTearDown(container.dispose);
    container.listen(storeTutorialControllerProvider, (final _, final _) {});
    await container.read(productsProvider.future);
    await container.read(storeTutorialFinishedProvider.future);
    await pumpEventQueue();
    return container.read(storeTutorialControllerProvider.notifier);
  }

  StoreTutorialState state() => container.read(storeTutorialControllerProvider);

  Future<StoreTutorialController> startAtSave() async {
    final controller = await start();
    controller
      ..enterAddProduct()
      ..mainImagePicked()
      ..imageAnalysisChanged(const AsyncData(null))
      ..next()
      ..next()
      ..next()
      ..next()
      ..next();
    return controller;
  }

  test('no products and not finished starts at add product', () async {
    await start();

    expect(state(), const StoreTutorialState.addProduct());
  });

  test('a store with products never starts', () async {
    await start(initial: [product('p1')]);

    expect(state(), const StoreTutorialState.inactive());
  });

  test('a finished store never starts', () async {
    await start(isFinished: true);

    expect(state(), const StoreTutorialState.inactive());
  });

  test('products error hides the tour until a successful load', () async {
    await start();

    products.emitError();
    expect(state(), const StoreTutorialState.inactive());

    products.emit(const []);
    expect(state(), const StoreTutorialState.addProduct());
  });

  test('the add page walks through the form steps', () async {
    final controller = await start();

    controller.enterAddProduct();
    expect(state(), const StoreTutorialState.pickImage());

    controller.mainImagePicked();
    expect(state(), const StoreTutorialState.analyzing());

    controller.imageAnalysisChanged(const AsyncData(null));
    expect(state(), const StoreTutorialState.reviewInfo());

    controller.next();
    expect(state(), const StoreTutorialState.price());

    controller.next();
    expect(state(), const StoreTutorialState.purchaseLink());

    controller.next();
    expect(state(), const StoreTutorialState.sizes());

    controller.next();
    expect(state(), const StoreTutorialState.publish());

    controller.next();
    expect(state(), const StoreTutorialState.save());
  });

  test('analysis settling before the image event still advances', () async {
    final controller = await start();

    controller
      ..enterAddProduct()
      ..imageAnalysisChanged(const AsyncData(null));

    expect(state(), const StoreTutorialState.reviewInfo());
  });

  test('a failed analysis still moves on to step 4', () async {
    final controller = await start();

    controller
      ..enterAddProduct()
      ..mainImagePicked()
      ..imageAnalysisChanged(
        const AsyncError(UnknownFailure('busy'), StackTrace.empty),
      );

    expect(state(), const StoreTutorialState.reviewInfo());
  });

  test('an analysis still running stays on step 3', () async {
    final controller = await start();

    controller
      ..enterAddProduct()
      ..mainImagePicked()
      ..imageAnalysisChanged(const AsyncLoading());

    expect(state(), const StoreTutorialState.analyzing());
  });

  test('removing the image during analysis returns to pick image', () async {
    final controller = await start();

    controller
      ..enterAddProduct()
      ..mainImagePicked()
      ..mainImageRemoved();

    expect(state(), const StoreTutorialState.pickImage());
  });

  test('leaving the add page returns to step 1', () async {
    final controller = await start();

    controller
      ..enterAddProduct()
      ..mainImagePicked()
      ..imageAnalysisChanged(const AsyncData(null))
      ..next()
      ..next()
      ..leaveAddProduct();

    expect(state(), const StoreTutorialState.addProduct());
  });

  test('reload keeps the current step', () async {
    final controller = await start();
    controller
      ..enterAddProduct()
      ..imageAnalysisChanged(const AsyncData(null))
      ..next();

    products.startReload();
    await pumpEventQueue();

    expect(container.read(productsProvider).isLoading, isTrue);
    expect(state(), const StoreTutorialState.price());
  });

  test('saving the first product shows it, then analytics', () async {
    final controller = await startAtSave();

    controller.productCreated(ProductStatus.active);
    expect(
      state(),
      const StoreTutorialState.reviewProduct(status: ProductStatus.active),
    );

    products.emit([product('p1')]);
    controller.leaveAddProduct();
    expect(
      state(),
      const StoreTutorialState.reviewProduct(status: ProductStatus.active),
    );

    controller.next();
    expect(state(), const StoreTutorialState.openAccount());

    controller.accountTabOpened();
    expect(state(), const StoreTutorialState.viewPerformance());

    await controller.finish();
    expect(state(), const StoreTutorialState.inactive());
  });

  test('saving an unlisted first product reviews it as archived', () async {
    final controller = await startAtSave();

    controller.productCreated(ProductStatus.archived);

    expect(
      state(),
      const StoreTutorialState.reviewProduct(status: ProductStatus.archived),
    );
    await pumpEventQueue();
    expect(finished.finishes, 1);
  });

  test('opening the account tab outside step 11 does nothing', () async {
    final controller = await startAtSave();

    controller.accountTabOpened();

    expect(state(), const StoreTutorialState.save());
  });

  test('a save that merges into the list before it reports shows it', () async {
    final controller = await startAtSave();

    products.emit([product('p1')]);
    controller.productCreated(ProductStatus.active);

    expect(
      state(),
      const StoreTutorialState.reviewProduct(status: ProductStatus.active),
    );
  });

  test(
    'a save whose read-back reloads instead of merging still shows it',
    () async {
      final controller = await startAtSave();

      controller.productCreated(ProductStatus.active);
      products.startReload();
      await pumpEventQueue();
      controller.leaveAddProduct();

      expect(
        state(),
        const StoreTutorialState.reviewProduct(status: ProductStatus.active),
      );
    },
  );

  test('a product created outside the form steps changes nothing', () async {
    final controller = await start();

    controller.productCreated(ProductStatus.active);

    expect(state(), const StoreTutorialState.addProduct());
  });

  test('next outside a next-able step does nothing', () async {
    final controller = await start();

    controller.next();

    expect(state(), const StoreTutorialState.addProduct());
  });

  test('finish persists and ends the tour', () async {
    final controller = await start();
    controller
      ..enterAddProduct()
      ..imageAnalysisChanged(const AsyncData(null));

    await controller.finish();
    expect(state(), const StoreTutorialState.inactive());
    expect(finished.finishes, 1);

    products.emit(const []);
    expect(state(), const StoreTutorialState.inactive());
  });

  test(
    'saving the first product persists while the last steps go on',
    () async {
      final controller = await startAtSave();

      controller.productCreated(ProductStatus.active);
      await pumpEventQueue();

      expect(finished.finishes, 1);
      expect(
        state(),
        const StoreTutorialState.reviewProduct(status: ProductStatus.active),
      );

      controller.next();
      expect(state(), const StoreTutorialState.openAccount());
    },
  );

  test('finishing after the save persists only once', () async {
    final controller = await startAtSave();
    controller
      ..productCreated(ProductStatus.active)
      ..next();

    await controller.finish();

    expect(finished.finishes, 1);
  });
}
