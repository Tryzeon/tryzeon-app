import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/pages/wardrobe_item_detail_page.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

Future<FakeWardrobeItems> pumpDetail(
  final WidgetTester tester, {
  required final List<WardrobeItem> items,
  final WardrobeItem? initialItem,
}) async {
  final notifier = FakeWardrobeItems(items);
  final container = ProviderContainer(
    overrides: [
      isAuthenticatedProvider.overrideWithValue(true),
      wardrobeItemsProvider.overrideWith(() => notifier),
      wardrobeItemImageProvider(
        'a.jpg',
      ).overrideWith((final ref) => Completer<File>().future),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: WardrobeItemDetailPage(itemId: 'a', initialItem: initialItem),
      ),
    ),
  );
  await tester.pump();
  return notifier;
}

void main() {
  testWidgets('keeps showing the initial item after it leaves the list', (
    final tester,
  ) async {
    final item = wardrobeItem('a');
    final notifier = await pumpDetail(
      tester,
      items: [item, wardrobeItem('b')],
      initialItem: item,
    );
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    notifier.setItems([wardrobeItem('b')]);
    await tester.pump();

    expect(find.text('找不到衣物'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('shows the listed item over the initial item', (
    final tester,
  ) async {
    final stale = wardrobeItem('a');
    final listed = stale.copyWith(tags: const ['linen']);
    await pumpDetail(tester, items: [listed], initialItem: stale);

    expect(find.text('#linen'), findsOneWidget);
  });

  testWidgets('shows the listed item when no initial item is given', (
    final tester,
  ) async {
    await pumpDetail(tester, items: [wardrobeItem('a')]);

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('shows not found when the list has no such item', (
    final tester,
  ) async {
    await pumpDetail(tester, items: [wardrobeItem('b')]);

    expect(find.text('找不到衣物'), findsOneWidget);
  });
}
