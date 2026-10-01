import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/tool_step_label.dart';

void main() {
  test('resolves category_code to the category name', () {
    final label = toolStepLabel(
      const ToolUseBlock(
        id: 't1',
        name: 'search_products',
        input: {'category_code': 'trousers', 'query': '牛仔'},
      ),
      const {'trousers': '長褲'},
    );

    expect(label, contains('長褲 · 牛仔'));
  });

  test('resolves garment_type to its display name', () {
    final label = toolStepLabel(
      const ToolUseBlock(
        id: 't2',
        name: 'search_wardrobe',
        input: {'garment_type': 'skirt'},
      ),
      const {},
    );

    expect(label, contains('裙子'));
  });
}
