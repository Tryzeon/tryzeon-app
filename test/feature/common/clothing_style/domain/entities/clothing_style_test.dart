import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';

void main() {
  test('offers the thirteen styles in display order', () {
    expect(ClothingStyle.values.map((final e) => e.value), [
      'basic',
      'casual',
      'business',
      'elegant',
      'sweet',
      'streetwear',
      'sporty',
      'vintage',
      'preppy',
      'edgy',
      'natural',
      'party',
      'homewear',
    ]);
  });

  test('labels each style with its shopper-facing name', () {
    expect(ClothingStyle.values.map((final e) => e.label), [
      '簡約基本',
      '休閒日常',
      '通勤正式',
      '優雅氣質',
      '甜美可愛',
      '街頭潮流',
      '運動機能',
      '復古',
      '學院',
      '個性酷帥',
      '文青自然',
      '性感派對',
      '居家舒適',
    ]);
  });

  test('drops a legacy value it no longer knows', () {
    expect(ClothingStyle.tryFromString('korean'), isNull);
    expect(ClothingStyle.listFromStrings(['korean', 'basic']), [
      ClothingStyle.basic,
    ]);
  });
}
