import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/product_fit_resolver.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_color_swatches.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_detail_body.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_image_viewer.dart';
import 'package:tryzeon/feature/personal/shop/providers/product_fit_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_pill_row.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../../../support/product_color_fixtures.dart';
import '../../../../../support/wardrobe_test_doubles.dart';

ProductColor _color(final String id, final List<String> images) =>
    productColorFixture(id: id, name: id, imagePaths: images);

ShopProduct _product(final List<ProductColor> colors) => ShopProduct(
  id: 'p1',
  storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
  name: 'Tee',
  categoryId: 'c',
  garmentType: GarmentType.top,
  price: 690,
  colors: colors,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _NoCategories extends ProductCategoriesNotifier {
  @override
  Future<List<ProductCategory>> build() async => const [];
}

final _two = _product([
  _color('A', ['a1.jpg', 'a2.jpg', 'a3.jpg']),
  _color('B', ['b1.jpg']),
]);

Future<void> _pump(
  final WidgetTester tester,
  final ShopProduct product, {
  final String? selectedColorId,
  final ValueChanged<ProductColor>? onColorSelected,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      isAuthenticatedProvider.overrideWithValue(true),
      wardrobeItemsProvider.overrideWith(() => FakeWardrobeItems(const [])),
      productCategoriesProvider.overrideWith(_NoCategories.new),
      productFitResolverProvider.overrideWithValue(
        const ProductFitResolver(body: null),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: ProductDetailBody(
          productAsync: AsyncValue.data(product),
          onRetry: () {},
          selectedColor: product.colors.resolve(selectedColorId),
          onColorSelected: onColorSelected ?? (_) {},
        ),
      ),
    ),
  ),
);

List<String> _viewerUrls(final WidgetTester tester) => tester
    .widget<ProductImageViewer>(find.byType(ProductImageViewer))
    .imageUrls;

void main() {
  testWidgets('a single-colour product shows no swatches', (
    final tester,
  ) async {
    await _pump(
      tester,
      _product([
        _color('A', ['a1.jpg']),
      ]),
    );

    expect(find.byType(ProductColorSwatches), findsNothing);
  });

  testWidgets('selecting a colour shows its images', (final tester) async {
    ProductColor? picked;
    await _pump(tester, _two, onColorSelected: (final c) => picked = c);

    expect(_viewerUrls(tester), _two.colors[0].imageUrls);
    final firstKey = tester
        .widget<ProductImageViewer>(find.byType(ProductImageViewer))
        .key;

    await tester.ensureVisible(find.byKey(const Key('color-swatch-B')));
    await tester.tap(find.byKey(const Key('color-swatch-B')));
    expect(picked, _two.colors[1]);

    await _pump(tester, _two, selectedColorId: 'B');
    await tester.pump();

    expect(_viewerUrls(tester), _two.colors[1].imageUrls);
    expect(
      tester.widget<ProductImageViewer>(find.byType(ProductImageViewer)).key,
      isNot(firstKey),
    );
  });

  testWidgets('the outfit pill wears the selected colour', (
    final tester,
  ) async {
    await _pump(tester, _two, selectedColorId: 'B');

    final pill = tester.widget<OutfitPillRow>(find.byType(OutfitPillRow));
    expect((pill.piece as OutfitPieceProduct).colorId, 'B');
  });

  testWidgets('offers a colour swap when the outfit holds another colour', (
    final tester,
  ) async {
    await _pump(tester, _two, selectedColorId: 'A');
    await tester.tap(find.text('搭配'));
    await tester.pump();
    expect(find.text('已加入'), findsOneWidget);

    await _pump(tester, _two, selectedColorId: 'B');
    expect(find.text('換成此色'), findsOneWidget);

    await tester.tap(find.text('換成此色'));
    await tester.pump();
    expect(find.text('已加入'), findsOneWidget);
  });
}
