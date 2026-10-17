import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/price_format_extension.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
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
            body: Center(child: SizedBox(width: 152, child: card)),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    'sets store, name and price below the photo with a try-on on it',
    (final tester) async {
      await _pump(tester, ChatProductCard(product: _product));

      final photo = tester.getRect(find.byType(AspectRatio));
      expect(find.text('STUDIO MUJI'), findsOneWidget);
      expect(find.text('米色寬鬆麻質長褲'), findsOneWidget);
      expect(find.text(599.asTwd), findsOneWidget);
      final name = tester.getTopLeft(find.text('米色寬鬆麻質長褲')).dy;
      final price = tester.getTopLeft(find.text(599.asTwd)).dy;
      final store = tester.getTopLeft(find.text('STUDIO MUJI')).dy;
      expect(store, greaterThan(photo.bottom));
      expect(name, greaterThan(store));
      expect(price, greaterThan(name));
      expect(find.byType(TryonFab), findsOneWidget);
      expect(find.byType(ChatImageTag), findsNothing);
    },
  );

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

  testWidgets('the photo is 3:4', (final tester) async {
    await _pump(tester, ChatProductCard(product: _product));

    final photo = tester.getSize(find.byType(AspectRatio));
    expect(photo.width, 152);
    expect(photo.height, closeTo(202.7, 0.5));
  });

  testWidgets(
    'the try-on pill stays small in the corner while its tap area reaches the minimum',
    (final tester) async {
      await _pump(tester, ChatProductCard(product: _product));

      final photo = tester.getRect(find.byType(AspectRatio));
      final pill = tester.getRect(
        find.descendant(
          of: find.byType(TryonFab),
          matching: find.byType(GlassPill),
        ),
      );
      final tapArea = tester.getSize(find.byType(TryonFab));

      expect(pill.height, lessThanOrEqualTo(30));
      expect(pill.width, lessThan(photo.width * 0.45));
      expect(photo.right - pill.right, closeTo(AppSpacing.sm, 1));
      expect(photo.bottom - pill.bottom, closeTo(AppSpacing.sm, 1));
      expect(tapArea.height, greaterThanOrEqualTo(kMinInteractiveDimension));
    },
  );
}
