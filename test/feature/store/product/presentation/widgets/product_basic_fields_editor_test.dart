import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_basic_fields_editor.dart';

void main() {
  Finder anchorOf(final CoachMarkTarget target) => find.byWidgetPredicate(
    (final w) => w is CoachMarkAnchor && w.target == target,
  );

  Future<void> pumpEditor(final WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductBasicFieldsEditor(
                nameController: TextEditingController(),
                priceController: TextEditingController(),
                purchaseLinkController: TextEditingController(),
                descriptionController: TextEditingController(),
                selectedGender: ValueNotifier<ProductGender?>(null),
                selectedCategoryId: ValueNotifier<String?>(null),
                onCategorySelected: (final _) {},
                productCategoriesAsync: const AsyncData([]),
                onRetryCategories: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the purchase-link target is the input box alone', (
    final tester,
  ) async {
    await pumpEditor(tester);

    final anchor = anchorOf(CoachMarkTarget.productPurchaseLink);
    expect(
      find.descendant(
        of: anchor,
        matching: find.text(ProductBasicFieldsEditor.purchaseLinkHelper),
      ),
      findsNothing,
    );
    expect(
      tester.getRect(anchor),
      tester.getRect(
        find.descendant(of: anchor, matching: find.byType(InputDecorator)),
      ),
    );
    expect(
      find.text(ProductBasicFieldsEditor.purchaseLinkHelper),
      findsOneWidget,
    );
  });

  testWidgets('the price target is the price input box', (final tester) async {
    await pumpEditor(tester);

    final anchor = anchorOf(CoachMarkTarget.productPrice);
    expect(
      tester.getRect(anchor),
      tester.getRect(
        find.descendant(of: anchor, matching: find.byType(InputDecorator)),
      ),
    );
  });
}
