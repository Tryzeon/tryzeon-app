import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

void main() {
  test('decodes a known value', () {
    expect(
      decodeCachedEnum('one_piece', GarmentType.tryFromString),
      GarmentType.onePiece,
    );
  });

  test('throws CacheDecodeException naming the enum and the value', () {
    expect(
      () => decodeCachedEnum('dress', GarmentType.tryFromString),
      throwsA(
        isA<CacheDecodeException>().having(
          (final e) => e.message,
          'message',
          allOf(contains('GarmentType'), contains('dress')),
        ),
      ),
    );
  });

  test('decodeCachedEnumOrNull passes null through', () {
    expect(decodeCachedEnumOrNull(null, GarmentType.tryFromString), isNull);
  });

  test('decodeCachedEnumOrNull throws on an unknown value', () {
    expect(
      () => decodeCachedEnumOrNull('dress', GarmentType.tryFromString),
      throwsA(isA<CacheDecodeException>()),
    );
  });

  test('decodeCachedEnumList throws when any element is unknown', () {
    expect(
      () => decodeCachedEnumList(['top', 'dress'], GarmentType.tryFromString),
      throwsA(isA<CacheDecodeException>()),
    );
  });

  test('decodeCachedEnumList decodes every element', () {
    expect(decodeCachedEnumList(['top', 'pants'], GarmentType.tryFromString), [
      GarmentType.top,
      GarmentType.pants,
    ]);
  });
}
