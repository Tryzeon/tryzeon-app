import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_description_section.dart';

void main() {
  testWidgets('renders the heading and the full multi-line description', (
    final tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProductDescriptionSection(description: '第一行\n第二行')),
      ),
    );

    expect(find.text('商品描述'), findsOneWidget);
    expect(find.text('第一行\n第二行'), findsOneWidget);
  });
}
