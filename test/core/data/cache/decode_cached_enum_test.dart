import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

void main() {
  test('decodes a known value', () {
    expect(
      decodeCachedEnum('one_piece', GarmentType.tryFromString, field: 'garmentType'),
      GarmentType.onePiece,
    );
  });

  test('throws CacheDecodeException naming the field on an unknown value', () {
    expect(
      () => decodeCachedEnum('dress', GarmentType.tryFromString, field: 'garmentType'),
      throwsA(
        isA<CacheDecodeException>().having(
          (final e) => e.message,
          'message',
          allOf(contains('garmentType'), contains('dress')),
        ),
      ),
    );
  });

  test('decodeCachedEnumOrNull passes null through', () {
    expect(
      decodeCachedEnumOrNull(null, GarmentType.tryFromString, field: 'garmentType'),
      isNull,
    );
  });

  test('decodeCachedEnumOrNull throws on an unknown value', () {
    expect(
      () => decodeCachedEnumOrNull('dress', GarmentType.tryFromString, field: 'g'),
      throwsA(isA<CacheDecodeException>()),
    );
  });

  test('decodeCachedEnumList throws when any element is unknown', () {
    expect(
      () => decodeCachedEnumList(
        ['top', 'dress'],
        GarmentType.tryFromString,
        field: 'garmentTypes',
      ),
      throwsA(isA<CacheDecodeException>()),
    );
  });

  test('decodeCachedEnumList decodes every element', () {
    expect(
      decodeCachedEnumList(['top', 'pants'], GarmentType.tryFromString, field: 'g'),
      [GarmentType.top, GarmentType.pants],
    );
  });
}
