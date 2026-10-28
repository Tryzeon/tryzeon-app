import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_rail.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_style.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_outfit_card.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/usage/providers/usage_quota_providers.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

ResolvedItem _product(
  final String id, {
  final GarmentType garmentType = GarmentType.top,
  final double price = 1000,
}) => ResolvedItem.product(
  ShopProduct(
    id: id,
    storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
    name: id,
    categoryId: 'c',
    garmentType: garmentType,
    price: price,
    colors: const [],
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

class _PendingUsageQuota extends UsageQuotaNotifier {
  @override
  Future<UsageQuota> build() => Completer<UsageQuota>().future;
}

Widget _card(final ResolvedOutfit outfit) => Scaffold(
  body: Center(
    child: SizedBox(
      width: ChatCardRail.outfitWidth,
      child: ChatOutfitCard(outfit: outfit),
    ),
  ),
);

Future<void> _pump(final WidgetTester tester, final ResolvedOutfit outfit) =>
    tester.pumpWidget(ProviderScope(child: MaterialApp(home: _card(outfit))));

Future<List<String>> _pumpRouted(
  final WidgetTester tester,
  final ResolvedOutfit outfit,
) async {
  final pushed = <String>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (final context, final state) => _card(outfit),
      ),
      GoRoute(
        path: AppRoutes.personalShopProductPath(':id'),
        builder: (final context, final state) {
          pushed.add(state.uri.path);
          return const SizedBox();
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [usageQuotaProvider.overrideWith(_PendingUsageQuota.new)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return pushed;
}

void main() {
  testWidgets('title, reason and purchase sit on the photo beside 試穿整套', (
    final tester,
  ) async {
    await _pump(
      tester,
      ResolvedOutfit(
        title: '週末休閒',
        reason: '白襯衫配深藍直筒',
        pieces: [_product('a'), _product('b'), _product('c')],
      ),
    );

    final card = tester.getRect(find.byType(AspectRatio));
    for (final text in ['週末休閒', '白襯衫配深藍直筒', '共 3 件', 3000.asTwd]) {
      expect(card.contains(tester.getCenter(find.text(text))), isTrue);
    }
    expect(tester.widget<Text>(find.text('週末休閒')).maxLines, 1);
    expect(tester.widget<Text>(find.text('白襯衫配深藍直筒')).maxLines, 2);
    final fab = tester.widget<TryonFab>(find.byType(TryonFab));
    expect(fab.label, '試穿整套');
    expect(fab.compact, isFalse);
    expect(fab.icon, isNull);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('an outfit with no reason skips that line', (final tester) async {
    await _pump(
      tester,
      ResolvedOutfit(title: '週末休閒', pieces: [_product('a'), _product('b')]),
    );

    expect(find.text('白襯衫配深藍直筒'), findsNothing);
    expect(find.text('共 2 件'), findsOneWidget);
  });

  testWidgets('the card is a 290:388 collage, whatever the count', (
    final tester,
  ) async {
    for (final pieces in [
      [_product('a'), _product('b')],
      [_product('a'), _product('b'), _product('c')],
    ]) {
      await _pump(tester, ResolvedOutfit(title: '週末休閒', pieces: pieces));

      final card = tester.getRect(find.byType(AspectRatio));
      expect(card.width, 290);
      expect(card.height, closeTo(388, 0.5));
      final cells = tester
          .widgetList(find.byType(ChatProductImage))
          .map((final w) => tester.getRect(find.byWidget(w)));
      expect(cells.map((final c) => c.bottom).reduce(max), card.bottom);
    }
  });

  testWidgets(
    'a trio leads with its outerwear in a 3fr cell beside two stacked',
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

      expect(coat.width / top.width, closeTo(3 / 2, 0.02));
      expect(coat.height, closeTo(388, 0.5));
      expect(top.left, pants.left);
      expect(top.top, lessThan(pants.top));
      expect(top.height, closeTo(pants.height, 0.5));
    },
  );

  testWidgets('tapping the words above a product cell opens that product', (
    final tester,
  ) async {
    final pushed = await _pumpRouted(
      tester,
      ResolvedOutfit(
        title: '週末休閒',
        reason: '白襯衫配深藍直筒',
        pieces: [_product('a'), _product('b')],
      ),
    );

    await tester.tap(find.text('週末休閒'));
    await tester.pumpAndSettle();
    expect(pushed, [AppRoutes.personalShopProductPath('a')]);
  });

  testWidgets('tapping 試穿整套 starts the try-on and opens nothing', (
    final tester,
  ) async {
    final pushed = await _pumpRouted(
      tester,
      ResolvedOutfit(title: '週末休閒', pieces: [_product('a'), _product('b')]),
    );

    await tester.tap(find.byType(TryonFab));
    await tester.pumpAndSettle();
    expect(pushed, isEmpty);
    expect(find.byType(TryonModeSheet), findsOneWidget);
  });

  testWidgets('a large total keeps the button whole', (final tester) async {
    await _pump(
      tester,
      ResolvedOutfit(
        title: '週末休閒',
        pieces: [
          _wardrobe('w'),
          _product('a', price: 100000),
          _product('b', price: 23456),
        ],
      ),
    );

    final label = find.descendant(
      of: find.byType(TryonFab),
      matching: find.text('試穿整套'),
    );
    final painter = TextPainter(
      text: TextSpan(text: '試穿整套', style: tester.widget<Text>(label).style),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(tester.getSize(label).width, closeTo(painter.width, 0.5));
    expect(find.text(123456.asTwd), findsOneWidget);
    expect(tester.takeException(), isNull);
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
      expect(tags, ['衣櫃']);
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

  testWidgets('the try-on keeps the text\'s inset from the right edge', (
    final tester,
  ) async {
    await _pump(
      tester,
      ResolvedOutfit(title: '週末休閒', pieces: [_product('a'), _product('b')]),
    );

    final card = tester.getRect(find.byType(AspectRatio));
    final pill = tester.getRect(
      find.descendant(
        of: find.byType(TryonFab),
        matching: find.byType(GlassPill),
      ),
    );
    final title = tester.getRect(find.text('週末休閒'));
    expect(card.right - pill.right, closeTo(title.left - card.left, 1));
  });

  testWidgets('the scrim is a light gradient with no solid band', (
    final tester,
  ) async {
    await _pump(
      tester,
      ResolvedOutfit(
        title: '週末休閒',
        reason: '白襯衫配深藍直筒',
        pieces: [_product('a'), _product('b'), _product('c')],
      ),
    );

    final gradient = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(ChatImageScrim),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((final box) => (box.decoration as BoxDecoration).gradient)
        .whereType<LinearGradient>()
        .single;
    expect(gradient.colors.last.a, closeTo(ChatCardStyle.scrimAlpha, 0.01));
    expect(
      find.descendant(
        of: find.byType(ChatImageScrim),
        matching: find.byType(ColoredBox),
      ),
      findsNothing,
    );
  });
}
