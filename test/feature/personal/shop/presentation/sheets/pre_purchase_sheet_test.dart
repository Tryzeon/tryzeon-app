import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/presentation/sheets/pre_purchase_sheet.dart';

import '../../../../../support/sheet_test_host.dart';

final _product = ShopProduct(
  storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
  name: 'White Tee',
  categoryId: 'c1',
  garmentType: GarmentType.top,
  price: 590,
  imagePaths: const [],
  imageUrls: const [],
  id: 'p1',
  purchaseLink: 'https://store.example/p1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  Future<({Future<PurchaseChoice?> result})> open(
    final WidgetTester tester, {
    required final FitResult fitResult,
  }) async {
    late Future<PurchaseChoice?> result;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (final _, final _) => Scaffold(
            body: Builder(
              builder: (final context) => TextButton(
                onPressed: () => result = PrePurchaseSheet.show(
                  context: context,
                  product: _product,
                  fitResult: fitResult,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.personalSettingsBodyMeasurements,
          builder: (final _, final _) =>
              const Scaffold(body: Text('body measurements')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    return (result: result);
  }

  testWidgets('sends a user without measurements to fill them in', (
    final tester,
  ) async {
    final sheet = await open(
      tester,
      fitResult: const FitResult(noUserData: true),
    );

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(PrePurchaseSheet), findsNothing);
    expect(await sheet.result, isNull);
    expect(find.text('body measurements'), findsOneWidget);
  });

  testWidgets('returns the online store choice', (final tester) async {
    final sheet = await open(tester, fitResult: const FitResult());

    await tester.tap(find.text('開啟購買連結'));
    await settle(tester);

    expect(await sheet.result, isA<OnlineStoreChoice>());
  });

  testWidgets('leaves dismissing to the drag and the barrier', (
    final tester,
  ) async {
    await open(tester, fitResult: const FitResult());

    expect(find.text('取消'), findsNothing);
  });
}
