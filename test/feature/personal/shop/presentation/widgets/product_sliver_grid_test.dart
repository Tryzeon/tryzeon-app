import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/product_fit_resolver.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/track_product_view.dart';
import 'package:tryzeon/feature/personal/shop/presentation/state/shop_products_notifier.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_sliver_grid.dart';
import 'package:tryzeon/feature/personal/shop/providers/product_fit_provider.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _NoopQueue implements AnalyticsEventQueue {
  @override
  dynamic noSuchMethod(final Invocation invocation) => null;
}

ShopProduct _product(final String id) => ShopProduct(
  id: id,
  storeInfo: const ShopStoreInfo(
    id: 's1',
    name: 'Store',
    channels: StoreChannel.all,
  ),
  name: 'Product $id',
  categoryId: 'c1',
  garmentType: GarmentType.top,
  price: 100,
  imagePaths: const [],
  imageUrls: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  setUp(
    () => VisibilityDetectorController.instance.updateInterval = Duration.zero,
  );

  Future<void> pumpGrid(
    final WidgetTester tester,
    final AsyncValue<ShopProductsState> productsAsync, {
    final CoachMarkTarget? firstTryonAnchor,
  }) async {
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
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ProductSliverGrid(
                  productsAsync: productsAsync,
                  onRetry: () {},
                  firstTryonAnchor: firstTryonAnchor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final anchors = find.byType(CoachMarkAnchor);

  testWidgets('only the first real card carries the anchor', (
    final tester,
  ) async {
    await pumpGrid(
      tester,
      AsyncData(
        ShopProductsState(
          items: [_product('p1'), _product('p2'), _product('p3')],
          hasMore: false,
        ),
      ),
      firstTryonAnchor: CoachMarkTarget.firstProductTryon,
    );

    expect(anchors, findsOneWidget);
    expect(
      find.ancestor(of: anchors, matching: find.byType(TryonFab)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: anchors, matching: find.byType(GlassPill)),
      findsOneWidget,
    );
  });

  testWidgets('skeleton cards carry no anchor', (final tester) async {
    await pumpGrid(
      tester,
      const AsyncLoading(),
      firstTryonAnchor: CoachMarkTarget.firstProductTryon,
    );

    expect(anchors, findsNothing);
  });

  testWidgets('no anchor without firstTryonAnchor', (final tester) async {
    await pumpGrid(
      tester,
      AsyncData(ShopProductsState(items: [_product('p1')], hasMore: false)),
    );

    expect(anchors, findsNothing);
  });
}
