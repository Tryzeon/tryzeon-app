import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_status_section.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

class _FakeProductEdit extends ProductEditNotifier {
  final statuses = <ProductStatus>[];

  @override
  ProductMutation? build() => null;

  @override
  Future<Result<void, Failure>> setStatus({
    required final Product product,
    required final ProductStatus status,
  }) async {
    statuses.add(status);
    return const Ok(null);
  }
}

Product _product(final ProductStatus status) => Product(
  storeId: 's1',
  name: 'White Tee',
  categoryId: 'c1',
  garmentType: GarmentType.top,
  price: 590,
  imagePaths: const [],
  imageUrls: const [],
  id: 'p1',
  status: status,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late _FakeProductEdit edit;

  setUp(() => edit = _FakeProductEdit());

  Future<void> pumpSection(
    final WidgetTester tester,
    final ProductStatus status, {
    final bool isBusy = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [productEditProvider.overrideWith(() => edit)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProductStatusSection(
              product: _product(status),
              isBusy: isBusy,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('archives a listed product', (final tester) async {
    await pumpSection(tester, ProductStatus.active);

    expect(find.text('上架中'), findsOneWidget);
    expect(find.text('顧客可以在商店看到這件商品'), findsOneWidget);

    await tester.tap(find.text('下架商品'));
    await settle(tester);

    expect(edit.statuses, [ProductStatus.archived]);
  });

  testWidgets('relists an archived product', (final tester) async {
    await pumpSection(tester, ProductStatus.archived);

    expect(find.text('已下架'), findsOneWidget);

    await tester.tap(find.text('重新上架'));
    await settle(tester);

    expect(edit.statuses, [ProductStatus.active]);
  });

  testWidgets('is disabled while another write is running', (
    final tester,
  ) async {
    await pumpSection(tester, ProductStatus.active, isBusy: true);

    await tester.tap(find.text('下架商品'));
    await settle(tester);

    expect(edit.statuses, isEmpty);
  });
}
