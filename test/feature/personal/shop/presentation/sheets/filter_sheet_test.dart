import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/presentation/sheets/filter_sheet.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_filter_provider.dart';

import '../../../../../support/sheet_test_host.dart';

void main() {
  ProviderContainer containerOf(final WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.text('open')));

  Future<void> open(final WidgetTester tester) async {
    await openSheet<void>(
      tester,
      (final context) => FilterSheet.show(context: context),
    );
    // Stands in for the shop page, which keeps the auto-dispose filter alive.
    containerOf(tester).listen(shopFilterProvider, (_, _) {});
  }

  Future<void> reopen(final WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> pickBothChannels(final WidgetTester tester) async {
    for (final channel in StoreChannel.values) {
      await tester.tap(find.text(channel.label));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('counts picked conditions on the apply button', (
    final tester,
  ) async {
    await open(tester);

    expect(find.text('套用'), findsOneWidget);

    await pickBothChannels(tester);

    expect(find.text('套用（2）'), findsOneWidget);
  });

  testWidgets('applies picked conditions and closes', (final tester) async {
    await open(tester);

    await pickBothChannels(tester);
    await tester.tap(find.text('套用（2）'));
    await tester.pumpAndSettle();

    expect(find.byType(FilterSheet), findsNothing);
    expect(
      containerOf(tester).read(shopFilterProvider).channels,
      StoreChannel.values.toSet(),
    );
  });

  testWidgets('discards picks on a drag dismiss', (final tester) async {
    await open(tester);

    await pickBothChannels(tester);
    await dismissByDrag(tester);

    expect(find.byType(FilterSheet), findsNothing);
    expect(containerOf(tester).read(shopFilterProvider).channels, isNull);
  });

  testWidgets('clear resets the sheet without closing or applying', (
    final tester,
  ) async {
    await open(tester);
    await pickBothChannels(tester);
    await tester.tap(find.text('套用（2）'));
    await tester.pumpAndSettle();
    await reopen(tester);

    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();

    expect(find.byType(FilterSheet), findsOneWidget);
    expect(find.text('套用'), findsOneWidget);
    expect(
      containerOf(tester).read(shopFilterProvider).channels,
      StoreChannel.values.toSet(),
    );

    await tester.tap(find.text('套用'));
    await tester.pumpAndSettle();

    expect(containerOf(tester).read(shopFilterProvider).channels, isNull);
  });
}
