import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/create_product.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/delete_product.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/list_products.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/set_product_status.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/update_product.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../support/store_test_doubles.dart';

const _draft = ProductDraft(
  name: 'renamed',
  categoryId: 'c1',
  garmentType: GarmentType.top,
  price: 100,
);

class _FakeListProducts implements ListProducts {
  var loads = 0;
  Failure? failure;

  @override
  Future<Result<List<Product>, Failure>> call({
    required final String storeId,
    final bool forceRefresh = false,
  }) async {
    loads++;
    if (failure case final failure?) return Err(failure);
    return Ok([product('a'), product('b')]);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeCreateProduct implements CreateProduct {
  Result<Product?, Failure> result = Ok(product('new'));

  @override
  Future<Result<Product?, Failure>> call(
    final CreateProductParams params,
  ) async => result;

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeUpdateProduct implements UpdateProduct {
  @override
  Future<Result<Product?, Failure>> call(
    final UpdateProductParams params,
  ) async => Ok(params.original.copyWith(name: params.draft.name));

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeSetProductStatus implements SetProductStatus {
  final pending = <Completer<void>>[];

  @override
  Future<Result<Product?, Failure>> call(
    final SetProductStatusParams params,
  ) async {
    final gate = Completer<void>();
    pending.add(gate);
    await gate.future;
    return Ok(params.product.copyWith(status: params.status));
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeDeleteProduct implements DeleteProduct {
  @override
  Future<Result<void, Failure>> call(final Product product) async =>
      const Ok(null);

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late ProviderContainer container;
  late _FakeListProducts list;
  late _FakeCreateProduct create;
  late _FakeSetProductStatus setStatus;

  setUp(() async {
    list = _FakeListProducts();
    create = _FakeCreateProduct();
    setStatus = _FakeSetProductStatus();
    container = ProviderContainer(
      retry: (final _, final _) => null,
      overrides: [
        storeProfileProvider.overrideWith(
          () => FakeStoreProfile(() async => storeProfile()),
        ),
        listProductsUseCaseProvider.overrideWithValue(list),
        createProductUseCaseProvider.overrideWithValue(create),
        updateProductUseCaseProvider.overrideWithValue(_FakeUpdateProduct()),
        setProductStatusUseCaseProvider.overrideWithValue(setStatus),
        deleteProductUseCaseProvider.overrideWithValue(_FakeDeleteProduct()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(productsProvider, (final _, final _) {});
    await container.read(productsProvider.future);
  });

  ProductsNotifier owner() => container.read(productsProvider.notifier);
  List<Product> products() => container.read(productsProvider).value!;

  test(
    'createProduct prepends the read-back product without refetching',
    () async {
      await owner().createProduct(
        draft: _draft,
        images: const [],
        sizes: const [],
      );

      expect([for (final p in products()) p.id], ['new', 'a', 'b']);
      expect(list.loads, 1);
    },
  );

  test('updateProduct replaces the product in place', () async {
    await owner().updateProduct(
      productId: 'b',
      draft: _draft,
      images: const [],
      sizes: const [],
    );

    expect([for (final p in products()) p.id], ['a', 'b']);
    expect(products()[1].name, 'renamed');
  });

  test('a write whose read-back failed rebuilds the list', () async {
    create.result = const Ok(null);

    await owner().createProduct(
      draft: _draft,
      images: const [],
      sizes: const [],
    );
    await container.read(productsProvider.future);

    expect(list.loads, 2);
  });

  test('toggling status twice keeps the second status', () async {
    final archive = owner().setProductStatus(
      product: product('a'),
      status: ProductStatus.archived,
    );
    final restore = owner().setProductStatus(
      product: product('a').copyWith(status: ProductStatus.archived),
      status: ProductStatus.active,
    );
    await pumpEventQueue();
    for (final gate in setStatus.pending) {
      gate.complete();
    }
    await Future.wait([archive, restore]);

    expect(products().first.status, ProductStatus.active);
  });

  test('deleteProduct removes the product', () async {
    await owner().deleteProduct(product('a'));

    expect([for (final p in products()) p.id], ['b']);
  });

  test('productById follows the list', () async {
    container.listen(productByIdProvider('b'), (final _, final _) {});
    await container.read(productByIdProvider('b').future);

    await owner().updateProduct(
      productId: 'b',
      draft: _draft,
      images: const [],
      sizes: const [],
    );
    await container.pump();

    expect(
      (await container.read(productByIdProvider('b').future)).name,
      'renamed',
    );
  });

  test(
    'updateProduct while the list failed to load returns that failure',
    () async {
      list.failure = const NetworkFailure();
      container.invalidate(productsProvider);
      await container
          .read(productsProvider.future)
          .catchError((final _) => <Product>[]);

      final result = await owner().updateProduct(
        productId: 'a',
        draft: _draft,
        images: const [],
        sizes: const [],
      );

      expect(result.getError(), isA<NetworkFailure>());
    },
  );
}
