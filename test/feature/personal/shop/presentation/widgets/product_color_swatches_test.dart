import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_color_swatches.dart';

import '../../../../../support/product_color_fixtures.dart';

ProductColor _color(final String id, {final String? name}) =>
    productColorFixture(id: id, name: name, imagePaths: ['$id.jpg']);

Future<void> _pump(
  final WidgetTester tester,
  final List<ProductColor> colors,
  final ProductColor selected,
  final ValueChanged<ProductColor> onSelected,
) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: ProductColorSwatches(
        colors: colors,
        selected: selected,
        onSelected: onSelected,
      ),
    ),
  ),
);

void main() {
  final a = _color('A', name: '黑色');
  final b = _color('B', name: '白色');

  testWidgets('shows one swatch per colour and the selected name', (
    final tester,
  ) async {
    await _pump(tester, [a, b], a, (_) {});

    expect(find.byKey(const Key('color-swatch-A')), findsOneWidget);
    expect(find.byKey(const Key('color-swatch-B')), findsOneWidget);
    expect(find.text('黑色'), findsOneWidget);
  });

  testWidgets('tapping a swatch reports that colour', (final tester) async {
    ProductColor? picked;
    await _pump(tester, [a, b], a, (final c) => picked = c);

    await tester.tap(find.byKey(const Key('color-swatch-B')));

    expect(picked, b);
  });

  testWidgets('hides the label when the selected colour has no name', (
    final tester,
  ) async {
    final unnamed = _color('C');
    await _pump(tester, [unnamed, b], unnamed, (_) {});

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('opens with a selected colour past the viewport in view', (
    final tester,
  ) async {
    final many = [for (var i = 0; i < 20; i++) _color('C$i')];
    await _pump(tester, many, many[15], (_) {});
    await tester.pump();

    final swatch = tester.getRect(find.byKey(const Key('color-swatch-C15')));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(swatch.left, greaterThanOrEqualTo(0));
    expect(swatch.right, lessThanOrEqualTo(screen.width));
  });
}
