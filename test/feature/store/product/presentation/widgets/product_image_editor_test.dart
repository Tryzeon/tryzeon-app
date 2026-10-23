import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_image_editor.dart';

void main() {
  testWidgets('the empty add block is the image coach-mark target', (
    final tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProductImageEditor(
              images: const [],
              onImagesChanged: (final _) {},
              onPickImage: () {},
            ),
          ),
        ),
      ),
    );

    final anchor = find.byWidgetPredicate(
      (final w) =>
          w is CoachMarkAnchor && w.target == CoachMarkTarget.productImages,
    );
    final block = find.ancestor(
      of: find.text('點擊新增'),
      matching: find.byType(Container),
    );
    expect(tester.getRect(anchor), tester.getRect(block.first));
  });
}
