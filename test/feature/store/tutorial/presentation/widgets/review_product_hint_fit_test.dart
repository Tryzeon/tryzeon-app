import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/bottom_nav_bar_inset.dart';
import 'package:tryzeon/core/router/shells/store_tab.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/presentation/pages/store_products_page.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_query_state.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/controllers/store_tutorial_controller.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/state/store_tutorial_state.dart';
import 'package:tryzeon/feature/store/tutorial/presentation/widgets/store_tutorial_overlay.dart';

import '../../../../../support/store_test_doubles.dart';

class _ReviewProduct extends StoreTutorialController {
  _ReviewProduct(this._status);

  final ProductStatus _status;

  @override
  StoreTutorialState build() =>
      StoreTutorialState.reviewProduct(status: _status);
}

class _ArchivedTab extends ProductQuery {
  @override
  ProductQueryState build() =>
      const ProductQueryState(status: ProductStatus.archived);
}

class _NoCategories extends ProductCategoriesNotifier {
  @override
  Future<List<ProductCategory>> build() async => const [];
}

class _NoAnalytics extends ProductAnalyticsSummariesNotifier {
  @override
  Future<List<ProductAnalyticsSummary>> build() async => const [];
}

void main() {
  for (final status in ProductStatus.values) {
    testWidgets(
      'step 10 for a ${status.name} product still shows on an iPhone 15 Pro '
      'with larger text',
      (final tester) async {
        tester.view.physicalSize = const Size(393, 852) * 3;
        tester.view.devicePixelRatio = 3;
        tester.view.padding = const FakeViewPadding(
          top: 59 * 3,
          bottom: 34 * 3,
        );
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storeTutorialControllerProvider.overrideWith(
                () => _ReviewProduct(status),
              ),
              productsProvider.overrideWith(
                () => FakeProducts([product('p1', status: status)]),
              ),
              if (status == ProductStatus.archived)
                productQueryProvider.overrideWith(_ArchivedTab.new),
              productAnalyticsSummariesProvider.overrideWith(_NoAnalytics.new),
              productCategoriesProvider.overrideWith(_NoCategories.new),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: BottomNavBarInset(
                overlap: 50,
                child: Builder(
                  builder: (final context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      disableAnimations: true,
                      textScaler: const TextScaler.linear(1.24),
                    ),
                    child: const StoreTutorialOverlay(
                      currentTab: StoreTab.products,
                      child: StoreProductsPage(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }

        expect(
          find
              .text(StoreTutorialOverlay.reviewProductMessage(status))
              .hitTestable(),
          findsOneWidget,
        );
      },
    );
  }
}
