import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_rail.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_style.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_product_card.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/usage/providers/usage_quota_providers.dart';

import '../../../../../support/product_color_fixtures.dart';

final _product = ShopProduct(
  id: 'p1',
  storeInfo: const ShopStoreInfo(id: 's1', name: 'Studio Muji', channels: {}),
  name: '米色寬鬆麻質長褲',
  categoryId: 'c',
  garmentType: GarmentType.pants,
  price: 599,
  colors: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _black = productColorFixture(
  id: 'black',
  name: '黑',
  imagePaths: const ['black.jpg'],
);
final _white = productColorFixture(
  id: 'white',
  name: '白',
  position: 1,
  imagePaths: const ['white.jpg'],
);
final _twoColours = _product.copyWith(colors: [_black, _white]);

class _PendingUsageQuota extends UsageQuotaNotifier {
  @override
  Future<UsageQuota> build() => Completer<UsageQuota>().future;
}

class _RecordingCoordinator implements TryonCoordinator {
  final pieces = <List<OutfitPiece>>[];

  @override
  Future<void> tryonFromOutfit(
    final List<OutfitPiece> pieces, {
    final TryonMode mode = TryonMode.image,
  }) async => this.pieces.add(pieces);

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Future<void> _pump(final WidgetTester tester, final Widget card) =>
    tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: ChatCardRail.itemWidth, child: card),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('the card is a 15:22 photo with source, name and price on it', (
    final tester,
  ) async {
    await _pump(tester, ChatProductCard(product: _product, color: null));

    final card = tester.getRect(find.byType(AspectRatio));
    expect(card.width, 172);
    expect(card.height, closeTo(252.3, 0.5));
    for (final text in ['STUDIO MUJI', '米色寬鬆麻質長褲', 599.asTwd]) {
      expect(card.contains(tester.getCenter(find.text(text))), isTrue);
    }
    final store = tester.getTopLeft(find.text('STUDIO MUJI')).dy;
    final nameBottom = tester.getBottomLeft(find.text('米色寬鬆麻質長褲')).dy;
    final price = tester.getTopLeft(find.text(599.asTwd)).dy;
    expect(store, closeTo(nameBottom, 1));
    expect(price, greaterThan(store));
    expect(find.byType(ChatImageTag), findsNothing);
  });

  testWidgets(
    'the try-on is the stock compact TryonFab beside store and price',
    (final tester) async {
      await _pump(tester, ChatProductCard(product: _product, color: null));

      final fab = tester.widget<TryonFab>(find.byType(TryonFab));
      expect(fab.label, '試穿');
      expect(fab.compact, isTrue);
      expect(fab.icon, isNull);
      final pill = tester.getRect(
        find.descendant(
          of: find.byType(TryonFab),
          matching: find.byType(GlassPill),
        ),
      );
      final store = tester.getRect(find.text('STUDIO MUJI'));
      final price = tester.getRect(find.text(599.asTwd));
      expect(pill.left, greaterThanOrEqualTo(store.right));
      expect(pill.left, greaterThanOrEqualTo(price.right));
      expect(
        (pill.center.dy - (store.top + price.bottom) / 2).abs(),
        lessThan(2),
      );
      expect(tester.getSize(find.byType(TryonFab)), pill.size);
    },
  );

  testWidgets('a long name stays on one line', (final tester) async {
    await _pump(
      tester,
      ChatProductCard(
        color: null,
        product: _product.copyWith(name: '米色寬鬆麻質長褲' * 6),
      ),
    );

    expect(tester.widget<Text>(find.text('米色寬鬆麻質長褲' * 6)).maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a highlight rides the top-left corner as a photo tag', (
    final tester,
  ) async {
    await _pump(
      tester,
      ChatProductCard(product: _product, color: null, highlight: '麻料透氣'),
    );

    final photo = tester.getRect(find.byType(AspectRatio));
    final tag = tester.getRect(find.byType(ChatImageTag));
    expect(
      tester.widget<ChatImageTag>(find.byType(ChatImageTag)).label,
      '麻料透氣',
    );
    expect(tag.left - photo.left, AppSpacing.sm);
    expect(tag.top - photo.top, AppSpacing.sm);
  });

  testWidgets('the text and the pill keep one inset from the sides and foot', (
    final tester,
  ) async {
    await _pump(tester, ChatProductCard(product: _product, color: null));

    final card = tester.getRect(find.byType(AspectRatio));
    final pill = tester.getRect(
      find.descendant(
        of: find.byType(TryonFab),
        matching: find.byType(GlassPill),
      ),
    );
    final source = tester.getRect(find.text('STUDIO MUJI'));
    final inset = source.left - card.left;
    expect(card.right - pill.right, closeTo(inset, 1));
    expect(card.bottom - pill.bottom, closeTo(inset, 1));
  });

  testWidgets(
    'the price keeps room for a five-digit amount beside the try-on',
    (final tester) async {
      await _pump(
        tester,
        ChatProductCard(color: null, product: _product.copyWith(price: 12345)),
      );

      expect(
        tester.getSize(find.text(12345.asTwd)).width,
        greaterThanOrEqualTo(80),
      );
    },
  );

  testWidgets('the scrim is a light gradient over less than half the card', (
    final tester,
  ) async {
    await _pump(tester, ChatProductCard(product: _product, color: null));

    final card = tester.getRect(find.byType(AspectRatio));
    final scrim = tester.getRect(find.byType(ChatImageScrim));
    expect(scrim.height, lessThan(card.height * 0.45));
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
    expect(gradient.colors.first.a, 0);
    expect(gradient.colors.last.a, closeTo(ChatCardStyle.scrimAlpha, 0.01));
    expect(
      find.descendant(
        of: find.byType(ChatImageScrim),
        matching: find.byType(ColoredBox),
      ),
      findsNothing,
    );
  });

  testWidgets('the photo is the first image of the chosen colour', (
    final tester,
  ) async {
    await _pump(tester, ChatProductCard(product: _twoColours, color: _white));

    expect(
      tester
          .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .imageUrl,
      'https://x/white.jpg',
    );
  });

  testWidgets('tapping opens the product on the chosen colour', (
    final tester,
  ) async {
    final pushed = <Uri>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (final context, final state) => Scaffold(
            body: ChatProductCard(product: _twoColours, color: _white),
          ),
        ),
        GoRoute(
          path: AppRoutes.personalShopProductPath(':id'),
          builder: (final context, final state) {
            pushed.add(state.uri);
            return const SizedBox();
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.tap(find.text('米色寬鬆麻質長褲'));
    await tester.pumpAndSettle();
    expect(pushed.map((final uri) => uri.toString()), [
      AppRoutes.personalShopProductPath('p1', colorId: 'white'),
    ]);
  });

  testWidgets('a one-colour product opens without a colour', (
    final tester,
  ) async {
    final oneColour = _product.copyWith(colors: [_black]);
    final pushed = <Uri>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (final context, final state) => Scaffold(
            body: ChatProductCard(product: oneColour, color: _black),
          ),
        ),
        GoRoute(
          path: AppRoutes.personalShopProductPath(':id'),
          builder: (final context, final state) {
            pushed.add(state.uri);
            return const SizedBox();
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.tap(find.text('米色寬鬆麻質長褲'));
    await tester.pumpAndSettle();
    expect(pushed.single.toString(), AppRoutes.personalShopProductPath('p1'));
  });

  testWidgets('the try-on carries the chosen colour', (final tester) async {
    final coordinator = _RecordingCoordinator();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tryonCoordinatorProvider.overrideWithValue(coordinator),
          usageQuotaProvider.overrideWith(_PendingUsageQuota.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: ChatCardRail.itemWidth,
                child: ChatProductCard(product: _twoColours, color: _white),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TryonFab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('圖片試穿'));
    await tester.pumpAndSettle();

    final piece = coordinator.pieces.single.single as OutfitPieceProduct;
    expect(piece.colorId, 'white');
    expect(piece.imageUrl, 'https://x/white.jpg');
  });
}
