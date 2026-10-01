import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';

const List<String> _hintKeys = [
  'category_code',
  'garment_type',
  'query',
  'gender',
  'styles',
  'seasons',
  'materials',
  'fits',
  'elasticities',
  'thicknesses',
  'channels',
  'tags',
];

String toolStepLabel(
  final ToolUseBlock block,
  final Map<String, String> categoryNameByCode,
) {
  final hint = _hint(block.input, categoryNameByCode);
  return [_action(block.name), if (hint.isNotEmpty) hint].join(' · ');
}

int toolStepItemCount(final ToolResultBlock block) {
  final items = block.content['items'];
  return items is List ? items.length : 0;
}

String _action(final String name) => switch (name) {
  'search_products' => '搜尋商品',
  'search_wardrobe' => '查詢衣櫃',
  _ => '搜尋',
};

String _hint(
  final Map<String, dynamic> input,
  final Map<String, String> categoryNameByCode,
) {
  final parts = <String>[];
  for (final key in _hintKeys) {
    final value = input[key];
    if (value is String && value.trim().isNotEmpty) {
      final text = value.trim();
      parts.add(switch (key) {
        'category_code' => categoryNameByCode[text] ?? text,
        'garment_type' => GarmentType.tryFromString(text)?.displayName ?? text,
        _ => text,
      });
    } else if (value is List && value.isNotEmpty) {
      parts.add(value.join(' '));
    }
  }
  final minPrice = input['min_price'];
  final maxPrice = input['max_price'];
  if (minPrice is num || maxPrice is num) {
    parts.add('${minPrice ?? ''}–${maxPrice ?? ''}');
  }
  return parts.join(' · ');
}
