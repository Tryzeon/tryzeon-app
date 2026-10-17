import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_rail.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_style.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_product_card.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

final _product = ShopProduct(
  id: 'p1',
  storeInfo: const ShopStoreInfo(id: 's1', name: 'Studio Muji', channels: {}),
  name: '米色寬鬆麻質長褲',
  categoryId: 'c',
  garmentType: GarmentType.pants,
  price: 599,
  imagePaths: const [],
  imageUrls: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

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
    await _pump(tester, ChatProductCard(product: _product));

    final card = tester.getRect(find.byType(AspectRatio));
    expect(card.width, 172);
    expect(card.height, closeTo(252.3, 0.5));
    for (final text in ['STUDIO MUJI', '米色寬鬆麻質長褲', 599.asTwd]) {
      expect(card.contains(tester.getCenter(find.text(text))), isTrue);
    }
    final store = tester.getTopLeft(find.text('STUDIO MUJI')).dy;
    final name = tester.getTopLeft(find.text('米色寬鬆麻質長褲')).dy;
    final price = tester.getTopLeft(find.text(599.asTwd)).dy;
    expect(name, greaterThan(store));
    expect(price, greaterThan(name));
    expect(find.byType(ChatImageTag), findsNothing);
  });

  testWidgets('the try-on is the stock compact TryonFab beside the price', (
    final tester,
  ) async {
    await _pump(tester, ChatProductCard(product: _product));

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
    final price = tester.getRect(find.text(599.asTwd));
    expect(pill.left, greaterThanOrEqualTo(price.right));
    expect((pill.center.dy - price.center.dy).abs(), lessThan(2));
    expect(
      tester.getSize(find.byType(TryonFab)).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
  });

  testWidgets('a long name stays on one line', (final tester) async {
    await _pump(
      tester,
      ChatProductCard(product: _product.copyWith(name: '米色寬鬆麻質長褲' * 6)),
    );

    expect(tester.widget<Text>(find.text('米色寬鬆麻質長褲' * 6)).maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a highlight rides the top-left corner as a photo tag', (
    final tester,
  ) async {
    await _pump(tester, ChatProductCard(product: _product, highlight: '麻料透氣'));

    final photo = tester.getRect(find.byType(AspectRatio));
    final tag = tester.getRect(find.byType(ChatImageTag));
    expect(
      tester.widget<ChatImageTag>(find.byType(ChatImageTag)).label,
      '麻料透氣',
    );
    expect(tag.left - photo.left, AppSpacing.sm);
    expect(tag.top - photo.top, AppSpacing.sm);
  });

  testWidgets('the try-on pill keeps the card\'s inset from its right edge', (
    final tester,
  ) async {
    await _pump(tester, ChatProductCard(product: _product));

    final card = tester.getRect(find.byType(AspectRatio));
    final pill = tester.getRect(
      find.descendant(
        of: find.byType(TryonFab),
        matching: find.byType(GlassPill),
      ),
    );
    final source = tester.getRect(find.text('STUDIO MUJI'));
    expect(card.right - pill.right, closeTo(source.left - card.left, 1));
  });

  testWidgets(
    'the price keeps room for a five-digit amount beside the try-on',
    (final tester) async {
      await _pump(
        tester,
        ChatProductCard(product: _product.copyWith(price: 12345)),
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
    await _pump(tester, ChatProductCard(product: _product));

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
}
