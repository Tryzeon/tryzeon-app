import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_season_selector.dart';

void main() {
  testWidgets('toggles seasons and clears selection when empty', (final tester) async {
    final selectedSeasons = ValueNotifier<List<ProductSeason>?>(null);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductSeasonSelector(selectedSeasons: selectedSeasons)),
      ),
    );

    expect(find.text('春'), findsOneWidget);
    expect(find.text('夏'), findsOneWidget);
    expect(find.text('秋'), findsOneWidget);
    expect(find.text('冬'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, '春'));
    await tester.pumpAndSettle();

    expect(selectedSeasons.value, [ProductSeason.spring]);

    await tester.tap(find.widgetWithText(FilterChip, '春'));
    await tester.pumpAndSettle();

    expect(selectedSeasons.value, isNull);
  });
}
