import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/product_fit_resolver.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/track_product_view.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_card.dart';
import 'package:tryzeon/feature/personal/shop/providers/product_fit_provider.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../support/product_color_fixtures.dart';

class _NoopQueue implements AnalyticsEventQueue {
  @override
  dynamic noSuchMethod(final Invocation invocation) => null;
}

ShopProduct _product({required final int colorCount}) {
  final colors = [
    for (var i = 0; i < colorCount; i++)
      productColorFixture(
        imagePaths: ['c$i.jpg'],
        position: i,
        name: 'colour $i',
      ),
  ];
  return ShopProduct(
    id: 'p1',
    storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
    name: 'Tee',
    categoryId: 'c1',
    garmentType: GarmentType.top,
    price: 100,
    colors: colors,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  setUp(
    () => VisibilityDetectorController.instance.updateInterval = Duration.zero,
  );

  Future<List<String>> pumpCard(
    final WidgetTester tester,
    final ShopProduct product,
  ) async {
    final pushed = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (final _, final _) =>
              Scaffold(body: ProductCard(product: product)),
        ),
        GoRoute(
          path: AppRoutes.personalShopProduct,
          builder: (final _, final state) {
            pushed.add(state.uri.toString());
            return const Scaffold(body: Text('detail'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productFitResolverProvider.overrideWithValue(
            const ProductFitResolver(body: null),
          ),
          trackProductViewProvider.overrideWithValue(
            TrackProductView(_NoopQueue()),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    return pushed;
  }

  testWidgets('shows the cover colour image and opens the product', (
    final tester,
  ) async {
    final pushed = await pumpCard(tester, _product(colorCount: 2));
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://x/c0.jpg');

    await tester.tap(find.text('Tee'));
    await tester.pumpAndSettle();
    expect(pushed.single, AppRoutes.personalShopProductPath('p1'));
  });
}
