import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/widgets/wardrobe_item_card.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

final _item = WardrobeItem(
  id: 'a',
  imagePath: 'a.jpg',
  garmentType: GarmentType.top,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Widget _harness({
  required final bool isSelected,
  required final VoidCallback onTap,
  required final VoidCallback onLongPress,
}) {
  return ProviderScope(
    overrides: [
      wardrobeItemImageProvider(
        _item.imagePath,
      ).overrideWith((final ref) => Completer<File>().future),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(
          width: 120,
          height: 160,
          child: WardrobeItemCard(
            item: _item,
            isSelected: isSelected,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('tap and long-press reach their callbacks', (final tester) async {
    var taps = 0;
    var longPresses = 0;
    await tester.pumpWidget(
      _harness(
        isSelected: false,
        onTap: () => taps++,
        onLongPress: () => longPresses++,
      ),
    );

    await tester.tap(find.byType(WardrobeItemCard));
    await tester.longPress(find.byType(WardrobeItemCard));

    expect(taps, 1);
    expect(longPresses, 1);
  });

  testWidgets('a selected card shows the check badge', (final tester) async {
    await tester.pumpWidget(
      _harness(isSelected: true, onTap: () {}, onLongPress: () {}),
    );

    expect(
      find.byKey(const Key('wardrobe-card-selected-badge')),
      findsOneWidget,
    );
  });

  testWidgets('an unselected card shows no badge', (final tester) async {
    await tester.pumpWidget(
      _harness(isSelected: false, onTap: () {}, onLongPress: () {}),
    );

    expect(find.byKey(const Key('wardrobe-card-selected-badge')), findsNothing);
  });
}
