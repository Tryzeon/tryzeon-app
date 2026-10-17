import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_images.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_rail.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_card_style.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_wardrobe_card.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

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
    overrides: [
      wardrobeItemImageProvider.overrideWith(
        (final ref, final imagePath) => Completer<File>().future,
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: ChatCardRail.itemWidth,
            child: ChatWardrobeCard(item: item, highlight: highlight),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('reads 衣櫃, the garment and two tags, and 已擁有 on the photo', (
    final tester,
  ) async {
    await _pump(tester, _item(tags: ['丹寧', '寬褲', '藍色', '秋季']));

    final card = tester.getRect(find.byType(AspectRatio));
    for (final text in ['衣櫃', '褲子 · 丹寧 · 寬褲', '已擁有']) {
      expect(card.contains(tester.getCenter(find.text(text))), isTrue);
    }
    expect(find.byType(ChatImageTag), findsNothing);
  });

  testWidgets('an item with no tags reads just its garment type', (
    final tester,
  ) async {
    await _pump(tester, _item());

    expect(find.text('褲子'), findsOneWidget);
  });

  testWidgets(
    'a loading image still shows the backdrop, the words and the try-on',
    (final tester) async {
      await _pump(tester, _item(tags: ['丹寧']));

      expect(
        find.byWidgetPredicate(
          (final w) =>
              w is ColoredBox && w.color == ChatCardStyle.cutoutBackdrop,
        ),
        findsOneWidget,
      );
      expect(find.text('衣櫃'), findsOneWidget);
      expect(find.text('已擁有'), findsOneWidget);
      expect(find.byType(TryonFab), findsOneWidget);
    },
  );

  testWidgets('the photo fills the card', (final tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [
            wardrobeItemImageProvider.overrideWith(
              (final ref, final imagePath) async => File('missing.png'),
            ),
          ],
          child: const ChatWardrobeImage(imagePath: 'w1.jpg'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
    expect(
      find.descendant(
        of: find.byType(ChatWardrobeImage),
        matching: find.byType(Padding),
      ),
      findsNothing,
    );
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

  testWidgets(
    'a long highlight ends in an ellipsis inside the photo, clear of the try-on',
    (final tester) async {
      await _pump(tester, _item(), highlight: '寬鬆好搭又顯瘦的高腰直筒丹寧寬褲');

      final photo = tester.getRect(find.byType(AspectRatio));
      final tag = tester.getRect(find.byType(ChatImageTag));
      expect(tag.right, lessThanOrEqualTo(photo.right - AppSpacing.sm));
      expect(tag.overlaps(tester.getRect(find.byType(TryonFab))), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the tag is a white pill with a hairline stroke', (
    final tester,
  ) async {
    await _pump(tester, _item(), highlight: '寬鬆好搭');

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(ChatImageTag),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    final colorScheme = Theme.of(
      tester.element(find.byType(ChatImageTag)),
    ).colorScheme;
    expect(decoration.color, colorScheme.surface);
    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.pill));
    expect(decoration.border!.top.width, AppStroke.thin);
    expect(
      decoration.border!.top.color,
      colorScheme.onSurface.withValues(alpha: ChatCardStyle.tagStrokeAlpha),
    );
  });
}
