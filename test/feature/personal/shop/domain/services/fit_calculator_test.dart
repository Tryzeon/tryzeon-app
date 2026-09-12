import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/fit_calculator.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

ProductSize _size(
  final String name,
  final GarmentMeasurements? garmentMeasurements, {
  final BodyMeasurementRanges? bodyMeasurementRanges,
}) => ProductSize(
  id: name,
  productId: 'p1',
  name: name,
  garmentMeasurements: garmentMeasurements,
  bodyMeasurementRanges: bodyMeasurementRanges,
  createdAt: _epoch,
  updatedAt: _epoch,
);

FitResult _calc(
  final BodyMeasurements? body,
  final List<ProductSize>? sizes, {
  final ProductFit? fit,
  final ProductElasticity? elasticity,
  final GarmentType garmentType = GarmentType.others,
}) => FitCalculator.calculate(
  body: body,
  productSizes: sizes,
  fit: fit,
  elasticity: elasticity,
  garmentType: garmentType,
);

void main() {
  group('FitCalculator.calculate', () {
    test('reports no user data when the shopper has no measurements', () {
      final result = _calc(null, [
        _size('M', const GarmentMeasurements(chestCircumference: 96)),
      ]);

      expect(result.displayState, FitDisplayState.noUserData);
    });

    test(
      'stays unknown when only height is recorded and no size states a height range',
      () {
        // Height has no garment counterpart, so without a published range there
        // is nothing to compare it against.
        final result = _calc(const BodyMeasurements(height: 170), [
          _size('M', const GarmentMeasurements(chestCircumference: 96)),
        ]);

        expect(result.displayState, FitDisplayState.unknown);
      },
    );

    test('stays unknown when no size overlaps the shopper dimensions', () {
      // Shopper has a chest; the only published dimension is length (display-only).
      final result = _calc(const BodyMeasurements(chest: 88), [
        _size('M', const GarmentMeasurements(length: 70)),
      ]);

      expect(result.displayState, FitDisplayState.unknown);
    });

    test('recommends the size whose ease lands in the regular band', () {
      // Body chest 88 → regular band [96, 103]. M at 100 fits, S runs tight,
      // L runs loose.
      final result = _calc(const BodyMeasurements(chest: 88), [
        _size('S', const GarmentMeasurements(chestCircumference: 92)),
        _size('M', const GarmentMeasurements(chestCircumference: 100)),
        _size('L', const GarmentMeasurements(chestCircumference: 110)),
      ]);

      expect(result.displayState, FitDisplayState.match);
      expect(result.recommendedSize, 'M');
      expect(result.matchedTypes, [BodyMeasurementType.chest]);
    });

    test('offers a second clean match as the alternative size', () {
      // Both M (100) and L (102) land in the regular band [96, 103] for chest 88.
      final result = _calc(const BodyMeasurements(chest: 88), [
        _size('M', const GarmentMeasurements(chestCircumference: 100)),
        _size('L', const GarmentMeasurements(chestCircumference: 102)),
      ]);

      expect(result.displayState, FitDisplayState.match);
      expect(result.recommendedSize, 'M');
      expect(result.alternativeSize, 'L');
    });

    test('recommends with a caveat when the closest size runs slightly tight', () {
      // Chest 88 → regular band [96, 103]. Nearest is 94 → body range [79, 86],
      // so 88 is above it by 2cm.
      final result = _calc(const BodyMeasurements(chest: 88), [
        _size('S', const GarmentMeasurements(chestCircumference: 94)),
      ]);

      expect(result.displayState, FitDisplayState.caveats);
      expect(result.recommendedSize, 'S');
      expect(result.caveats, hasLength(1));
      final caveat = result.caveats.single;
      expect(caveat.type, BodyMeasurementType.chest);
      expect(caveat.direction, FitDirection.above);
      expect(caveat.deviation, closeTo(2, 0.001));
    });

    test('flags out of range when no size comes close enough', () {
      // Chest 120 → regular band [128, 135]. Largest garment 100 misses by 28cm.
      final result = _calc(const BodyMeasurements(chest: 120), [
        _size('M', const GarmentMeasurements(chestCircumference: 100)),
      ]);

      expect(result.displayState, FitDisplayState.outOfRange);
      expect(result.recommendedSize, isNull);
      // Nothing to recommend, but the only stocked size still gets tried on.
      expect(result.tryonSizeId, 'M');
    });

    test('lets a stretchy fabric accept low ease as a clean fit', () {
      // Chest 88, garment 91 → 3cm ease. Regular band [96, 103] on a woven runs
      // tight; high stretch drops the band minimum to 87, so 91 fits cleanly.
      final woven = _calc(const BodyMeasurements(chest: 88), [
        _size('M', const GarmentMeasurements(chestCircumference: 91)),
      ], elasticity: ProductElasticity.none);
      final knit = _calc(const BodyMeasurements(chest: 88), [
        _size('M', const GarmentMeasurements(chestCircumference: 91)),
      ], elasticity: ProductElasticity.high);

      expect(woven.displayState, FitDisplayState.caveats);
      expect(knit.displayState, FitDisplayState.match);
      expect(knit.recommendedSize, 'M');
    });

    test('judges each dimension independently and reports every miss', () {
      // Chest 84 → regular band [92, 99]; garment 100 → body range [85, 92],
      // 84 is below by 1. Waist 70 → trouser band [71, 74]; garment 76 → body
      // range [72, 75], 70 is below by 2.
      final result = _calc(const BodyMeasurements(chest: 84, waist: 70), [
        _size(
          'M',
          const GarmentMeasurements(chestCircumference: 100, waistCircumference: 76),
        ),
      ]);

      expect(result.displayState, FitDisplayState.caveats);
      final byType = {for (final c in result.caveats) c.type: c};
      expect(byType[BodyMeasurementType.chest]?.direction, FitDirection.below);
      expect(byType[BodyMeasurementType.waist]?.direction, FitDirection.below);
    });

    test('recommends a size the per-dimension cap allows over a lower total miss', () {
      // Ranking by summed deviation alone would crown A, which the
      // per-dimension cap then rejects — burying B, which the cap allows.
      // Waist 70 -> band [71, 74]; hips 95 -> band [99, 104].
      //   A: waist 71 in range, hips 112 loose by 8 -> total 8, worst 8 (capped)
      //   B: waist 66 tight by 5, hips 95 tight by 4 -> total 9, worst 5 (ok)
      final result = _calc(const BodyMeasurements(waist: 70, hips: 95), [
        _size(
          'A',
          const GarmentMeasurements(waistCircumference: 71, hipCircumference: 112),
        ),
        _size(
          'B',
          const GarmentMeasurements(waistCircumference: 66, hipCircumference: 95),
        ),
      ]);

      expect(result.displayState, FitDisplayState.caveats);
      expect(result.recommendedSize, 'B');
    });

    test('flags out of range when every size exceeds the per-dimension cap', () {
      // Chest 88 -> band [96, 103]. Both sizes miss by more than 6cm, so the
      // filter empties and there is nothing left to recommend.
      final result = _calc(const BodyMeasurements(chest: 88), [
        _size('S', const GarmentMeasurements(chestCircumference: 88)),
        _size('L', const GarmentMeasurements(chestCircumference: 112)),
      ]);

      expect(result.displayState, FitDisplayState.outOfRange);
      expect(result.recommendedSize, isNull);
      // Still try-on-able: 'L' misses by 9cm, 'S' by 8cm, so 'S' is closest.
      expect(result.tryonSizeId, 'S');
    });

    test('compares thigh and matches within the recalibrated band', () {
      // Thigh 55 → regular band [58, 62]; garment 58 → 3cm ease, a clean fit.
      final result = _calc(const BodyMeasurements(thigh: 55), [
        _size('M', const GarmentMeasurements(thighCircumference: 58)),
      ]);

      expect(result.displayState, FitDisplayState.match);
      expect(result.recommendedSize, 'M');
      expect(result.matchedTypes, [BodyMeasurementType.thigh]);
    });

    test('reports the recommended size by id as well as by name', () {
      final result = _calc(const BodyMeasurements(chest: 92), [
        _size('S', const GarmentMeasurements(chestCircumference: 94)),
        _size('M', const GarmentMeasurements(chestCircumference: 103)),
      ]);

      expect(result.recommendedSize, 'M');
      expect(result.tryonSizeId, 'M');
    });

    test('reports the size id even when the best size carries caveats', () {
      final result = _calc(const BodyMeasurements(chest: 92), [
        _size('XL', const GarmentMeasurements(chestCircumference: 112)),
      ]);

      expect(result.displayState, FitDisplayState.caveats);
      expect(result.tryonSizeId, 'XL');
    });

    test('has no recommended size id when the shopper has no measurements', () {
      final result = _calc(null, [
        _size('M', const GarmentMeasurements(chestCircumference: 103)),
      ]);

      expect(result.tryonSizeId, isNull);
    });

    test('recommends the size whose wearer height range holds the shopper', () {
      final result = _calc(const BodyMeasurements(height: 168), [
        _size(
          'S',
          null,
          bodyMeasurementRanges: const BodyMeasurementRanges(
            height: MeasurementRange(min: 150, max: 160),
          ),
        ),
        _size(
          'M',
          null,
          bodyMeasurementRanges: const BodyMeasurementRanges(
            height: MeasurementRange(min: 160, max: 170),
          ),
        ),
        _size(
          'L',
          null,
          bodyMeasurementRanges: const BodyMeasurementRanges(
            height: MeasurementRange(min: 170, max: 180),
          ),
        ),
      ]);

      expect(result.displayState, FitDisplayState.match);
      expect(result.recommendedSize, 'M');
      expect(result.matchedTypes, [BodyMeasurementType.height]);
    });

    test(
      'prefers the size whose range is centred on the shopper when several hold them',
      () {
        // 165 sits at M's centre and at L's lower bound.
        final result = _calc(const BodyMeasurements(height: 165), [
          _size(
            'L',
            null,
            bodyMeasurementRanges: const BodyMeasurementRanges(
              height: MeasurementRange(min: 165, max: 175),
            ),
          ),
          _size(
            'M',
            null,
            bodyMeasurementRanges: const BodyMeasurementRanges(
              height: MeasurementRange(min: 160, max: 170),
            ),
          ),
        ]);

        expect(result.recommendedSize, 'M');
        expect(result.alternativeSize, 'L');
      },
    );

    test('reports a below-range weight as a caveat in kilograms', () {
      final result = _calc(const BodyMeasurements(weight: 47), [
        _size(
          'M',
          null,
          bodyMeasurementRanges: const BodyMeasurementRanges(
            weight: MeasurementRange(min: 50, max: 60),
          ),
        ),
      ]);

      expect(result.displayState, FitDisplayState.caveats);
      final caveat = result.caveats.single;
      expect(caveat.type, BodyMeasurementType.weight);
      expect(caveat.direction, FitDirection.below);
      expect(caveat.deviation, closeTo(3, 0.001));
    });

    test('reports an above-range height as a caveat', () {
      final result = _calc(const BodyMeasurements(height: 174), [
        _size(
          'M',
          null,
          bodyMeasurementRanges: const BodyMeasurementRanges(
            height: MeasurementRange(min: 160, max: 170),
          ),
        ),
      ]);

      expect(result.caveats.single.direction, FitDirection.above);
      expect(result.caveats.single.deviation, closeTo(4, 0.001));
    });

    test(
      'flags out of range when the shopper is far outside every body measurement range',
      () {
        final result = _calc(const BodyMeasurements(height: 190), [
          _size(
            'M',
            null,
            bodyMeasurementRanges: const BodyMeasurementRanges(
              height: MeasurementRange(min: 160, max: 170),
            ),
          ),
        ]);

        expect(result.displayState, FitDisplayState.outOfRange);
        expect(result.tryonSizeId, 'M');
      },
    );

    test('lets a published waist range override the ease estimate for waist', () {
      // Waist 70 against garment waist 76 is loose by 2cm on the ease table,
      // but the store says this size fits waists 68–72, and the store wins.
      final result = _calc(const BodyMeasurements(waist: 70), [
        _size(
          'M',
          const GarmentMeasurements(waistCircumference: 76),
          bodyMeasurementRanges: const BodyMeasurementRanges(
            waist: MeasurementRange(min: 68, max: 72),
          ),
        ),
      ]);

      expect(result.displayState, FitDisplayState.match);
      expect(result.matchedTypes, [BodyMeasurementType.waist]);
    });

    test('judges ease and range dimensions together and reports each once', () {
      // Chest 88 → regular band [96, 103]; garment 100 fits.
      // Height 175 against 160–170 → above by 5.
      final result = _calc(const BodyMeasurements(height: 175, chest: 88), [
        _size(
          'M',
          const GarmentMeasurements(chestCircumference: 100),
          bodyMeasurementRanges: const BodyMeasurementRanges(
            height: MeasurementRange(min: 160, max: 170),
          ),
        ),
      ]);

      expect(result.displayState, FitDisplayState.caveats);
      expect(result.matchedTypes, [BodyMeasurementType.chest]);
      expect(result.caveats.single.type, BodyMeasurementType.height);
    });

    test(
      'lets a measured circumference outvote height when neither size fits cleanly',
      () {
        // Both sizes miss on one dimension. A misses on height (weight 0.5),
        // B misses on chest (weight 1) by the same amount, so A ranks first.
        final result = _calc(const BodyMeasurements(height: 175, chest: 88), [
          _size(
            'A',
            const GarmentMeasurements(chestCircumference: 100),
            bodyMeasurementRanges: const BodyMeasurementRanges(
              height: MeasurementRange(min: 160, max: 172),
            ),
          ),
          _size(
            'B',
            const GarmentMeasurements(chestCircumference: 93),
            bodyMeasurementRanges: const BodyMeasurementRanges(
              height: MeasurementRange(min: 170, max: 180),
            ),
          ),
        ]);

        expect(result.recommendedSize, 'A');
      },
    );

    test('ignores body dimensions the garment type does not have', () {
      // Chest 60 is deliberately absurd: judged, it would sink M. Pants have no
      // chest, so only the waist counts. Waist 70 → trouser band [71, 74].
      final result = _calc(
        const BodyMeasurements(chest: 90, waist: 70),
        [
          _size(
            'M',
            const GarmentMeasurements(chestCircumference: 60, waistCircumference: 73),
          ),
        ],
        garmentType: GarmentType.pants,
      );

      expect(result.recommendedSize, 'M');
      expect(result.matchedTypes, [BodyMeasurementType.waist]);
    });

    test('still judges height against a published range on any garment type', () {
      final result = _calc(
        const BodyMeasurements(height: 190),
        [
          _size(
            'M',
            null,
            bodyMeasurementRanges: const BodyMeasurementRanges(
              height: MeasurementRange(min: 160, max: 170),
            ),
          ),
        ],
        garmentType: GarmentType.pants,
      );

      expect(result.recommendedSize, isNull);
      expect(result.outOfRange, isTrue);
    });
  });
}
