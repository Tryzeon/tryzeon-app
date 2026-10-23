import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_status_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_publish_section.dart';

void main() {
  Future<ValueNotifier<ProductStatus>> pump(
    final WidgetTester tester,
    final ProductStatus initial,
  ) async {
    final status = ValueNotifier<ProductStatus>(initial);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: ProductPublishSection(status: status)),
        ),
      ),
    );
    return status;
  }

  testWidgets('a published product shows the switch on with its description', (
    final tester,
  ) async {
    await pump(tester, ProductStatus.active);

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(find.text('上架到商店'), findsOneWidget);
    expect(find.text(ProductStatus.active.description), findsOneWidget);
  });

  testWidgets(
    'toggling the switch writes the status and swaps the description',
    (final tester) async {
      final status = await pump(tester, ProductStatus.active);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(status.value, ProductStatus.archived);
      expect(find.text(ProductStatus.archived.description), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
    },
  );

  testWidgets('the switch is the tutorial anchor', (final tester) async {
    await pump(tester, ProductStatus.active);

    expect(
      find.ancestor(
        of: find.byType(SwitchListTile),
        matching: find.byWidgetPredicate(
          (final w) =>
              w is CoachMarkAnchor &&
              w.target == CoachMarkTarget.productPublish,
        ),
      ),
      findsOneWidget,
    );
  });
}
