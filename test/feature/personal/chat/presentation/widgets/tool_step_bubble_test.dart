import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/tool_step_bubble.dart';

Widget _bubble(final ToolUseBlock block) => ProviderScope(
  overrides: [
    productCategoriesProvider.overrideWith(
      (final ref) => const [
        ProductCategory(
          id: 'c1',
          code: 'trousers',
          name: '長褲',
          defaultGarmentType: GarmentType.pants,
        ),
      ],
    ),
  ],
  child: MaterialApp(
    home: Scaffold(body: ToolUseBubble(block: block)),
  ),
);

void main() {
  testWidgets('resolves category_code to the category name', (final tester) async {
    await tester.pumpWidget(
      _bubble(
        const ToolUseBlock(
          id: 't1',
          name: 'search_products',
          input: {'category_code': 'trousers', 'query': '牛仔'},
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('長褲 · 牛仔'), findsOneWidget);
  });

  testWidgets('resolves garment_type to its display name', (final tester) async {
    await tester.pumpWidget(
      _bubble(
        const ToolUseBlock(
          id: 't2',
          name: 'search_wardrobe',
          input: {'garment_type': 'skirt'},
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('裙子'), findsOneWidget);
  });
}
