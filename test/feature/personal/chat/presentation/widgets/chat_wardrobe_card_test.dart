import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_wardrobe_card.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

WardrobeItem _item({final List<String> tags = const []}) => WardrobeItem(
  id: 'w1',
  imagePath: 'w1.jpg',
  garmentType: GarmentType.pants,
  tags: tags,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<void> _pump(
  final WidgetTester tester,
  final WardrobeItem item, {
  final String? highlight,
}) => tester.pumpWidget(
  ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 152,
            child: ChatWardrobeCard(item: item, highlight: highlight),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'stands the wardrobe where a store would, then type and tags, with a clean photo',
    (final tester) async {
      await _pump(tester, _item(tags: ['丹寧', '寬褲', '藍色', '秋季']));

      final photo = tester.getRect(find.byType(AspectRatio));
      final source = tester.getTopLeft(find.text('你的衣櫃'));
      final description = tester.getTopLeft(find.text('褲子 · 丹寧 · 寬褲 · 藍色'));
      expect(source.dy, greaterThan(photo.bottom));
      expect(description.dy, greaterThan(source.dy));
      expect(find.byType(ChatImageTag), findsNothing);
    },
  );

  testWidgets('an item with no tags reads just its garment type', (
    final tester,
  ) async {
    await _pump(tester, _item());

    expect(find.text('褲子'), findsOneWidget);
  });

  testWidgets('a highlight rides the top-left corner like a product\'s', (
    final tester,
  ) async {
    await _pump(tester, _item(), highlight: '寬鬆好搭');

    final photo = tester.getRect(find.byType(AspectRatio));
    final tag = tester.getRect(find.byType(ChatImageTag));
    expect(
      tester.widget<ChatImageTag>(find.byType(ChatImageTag)).label,
      '寬鬆好搭',
    );
    expect(tag.left - photo.left, AppSpacing.sm);
    expect(tag.top - photo.top, AppSpacing.sm);
  });

  testWidgets('a long highlight ends in an ellipsis inside the photo', (
    final tester,
  ) async {
    await _pump(tester, _item(), highlight: '寬鬆好搭又顯瘦的高腰直筒丹寧寬褲');

    final photo = tester.getRect(find.byType(AspectRatio));
    final tag = tester.getRect(find.byType(ChatImageTag));
    expect(tag.right, lessThanOrEqualTo(photo.right - AppSpacing.sm));
    expect(tester.takeException(), isNull);
  });
}
