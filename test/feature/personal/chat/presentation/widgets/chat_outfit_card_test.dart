import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_outfit_card.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

ResolvedItem _product(
  final String id, {
  final GarmentType garmentType = GarmentType.top,
}) => ResolvedItem.product(
  ShopProduct(
    id: id,
    storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
    name: id,
    categoryId: 'c',
    garmentType: garmentType,
    price: 1000,
    imagePaths: const [],
    imageUrls: const [],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
);

ResolvedItem _wardrobe(final String id) => ResolvedItem.wardrobe(
  WardrobeItem(
    id: id,
    imagePath: '$id.jpg',
    garmentType: GarmentType.pants,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
);

Future<void> _pump(final WidgetTester tester, final ResolvedOutfit outfit) =>
    tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 276,
                height: 520,
                child: ChatOutfitCard(outfit: outfit),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    'reads title, reason, how many to buy and their total, and offers the whole try-on',
    (final tester) async {
      await _pump(
        tester,
        ResolvedOutfit(
          title: '週末休閒',
          reason: '白襯衫配深藍直筒',
          pieces: [_product('a'), _product('b'), _product('c')],
        ),
      );

      expect(find.text('週末休閒'), findsOneWidget);
      expect(find.text('白襯衫配深藍直筒'), findsOneWidget);
      expect(find.text('共 3 件'), findsOneWidget);
      expect(find.text(3000.asTwd), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '試穿整套'), findsOneWidget);
    },
  );

  testWidgets('an outfit with no reason skips that line', (final tester) async {
    await _pump(
      tester,
      ResolvedOutfit(title: '週末休閒', pieces: [_product('a'), _product('b')]),
    );

    expect(find.text('白襯衫配深藍直筒'), findsNothing);
    expect(find.text('共 2 件'), findsOneWidget);
  });

  testWidgets('the collage stands at 9:8 above the text, whatever the count', (
    final tester,
  ) async {
    for (final pieces in [
      [_product('a'), _product('b')],
      [_product('a'), _product('b'), _product('c')],
    ]) {
      await _pump(tester, ResolvedOutfit(title: '週末休閒', pieces: pieces));

      final collage = tester.getRect(find.byType(AspectRatio));
      expect(collage.width, 276);
      expect(collage.height, closeTo(245.3, 0.5));
      expect(
        tester.getTopLeft(find.text('週末休閒')).dy,
        greaterThan(collage.bottom),
      );
    }
  });

  testWidgets(
    'a trio leads with its outerwear in a 3:4 cell beside two stacked 3:4 cells',
    (final tester) async {
      await _pump(
        tester,
        ResolvedOutfit(
          title: '週末休閒',
          pieces: [
            _product('top'),
            _wardrobe('pants'),
            _product('coat', garmentType: GarmentType.outerwear),
          ],
        ),
      );

      Rect product(final String id) => tester.getRect(
        find.byWidgetPredicate(
          (final widget) =>
              widget is ChatProductImage && widget.product.id == id,
        ),
      );
      final coat = product('coat');
      final top = product('top');
      final pants = tester.getRect(find.byType(ChatWardrobeImage));

      for (final cell in [coat, top, pants]) {
        expect(cell.width / cell.height, closeTo(3 / 4, 0.01));
      }
      expect(coat.left, lessThan(top.left));
      expect(top.left, pants.left);
      expect(top.top, lessThan(pants.top));
    },
  );

  testWidgets('the title is not a link: only a collage cell opens its piece', (
    final tester,
  ) async {
    final pushed = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (final context, final state) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 276,
                height: 520,
                child: ChatOutfitCard(
                  outfit: ResolvedOutfit(
                    title: '週末休閒',
                    reason: '白襯衫配深藍直筒',
                    pieces: [_product('a'), _product('b')],
                  ),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.personalShopProductPath('a'),
          builder: (final context, final state) {
            pushed.add(state.uri.path);
            return const SizedBox();
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.tap(find.text('週末休閒'));
    await tester.pumpAndSettle();
    expect(pushed, isEmpty);

    final collage = tester.getRect(find.byType(AspectRatio));
    await tester.tapAt(Offset(collage.left + 20, collage.bottom - 20));
    await tester.pumpAndSettle();
    expect(pushed, [AppRoutes.personalShopProductPath('a')]);
  });

  testWidgets(
    'only an owned cell is marked, and the footer counts what is left to buy',
    (final tester) async {
      await _pump(
        tester,
        ResolvedOutfit(title: '週末休閒', pieces: [_product('a'), _wardrobe('w')]),
      );

      final tags = tester
          .widgetList<ChatImageTag>(find.byType(ChatImageTag))
          .map((final tag) => tag.label);
      expect(tags, ['你的衣櫃']);
      expect(find.text('再買 1 件'), findsOneWidget);
      expect(find.text(1000.asTwd), findsOneWidget);
    },
  );

  testWidgets('a look made only of owned pieces carries no cell tags', (
    final tester,
  ) async {
    await _pump(
      tester,
      ResolvedOutfit(title: '週末休閒', pieces: [_wardrobe('a'), _wardrobe('b')]),
    );

    expect(find.byType(ChatImageTag), findsNothing);
    expect(find.text('全部來自你的衣櫃'), findsOneWidget);
  });
}
