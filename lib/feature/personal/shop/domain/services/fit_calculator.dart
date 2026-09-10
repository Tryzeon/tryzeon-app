import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/ease_table.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/fit_dimension_weights.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/garment_fit_dimension.dart';

/// For every published size it judges each body dimension the shopper has
/// recorded and decides whether the size fits, runs tight, or runs loose.
///
/// A dimension is judged one of two ways. If the store published a wearer
/// range for it, the shopper's value is checked against that range — the store
/// knows its own cut better than a generic ease table, so the range wins and
/// the ease estimate is not consulted. Otherwise, if the dimension has a
/// garment counterpart, the *ease* (garment minus body) is checked against the
/// expected band. Dimensions with neither are skipped rather than guessed, so a
/// size judged on chest alone says so ("chest fits") instead of implying a
/// full-body match.
class FitCalculator {
  FitCalculator._();

  static FitResult calculate({
    required final BodyMeasurements? body,
    required final List<ProductSize>? productSizes,
    required final ProductFit? fit,
    required final ProductElasticity? elasticity,
  }) {
    final userDimensions = BodyMeasurementType.values
        .where((final t) => body?.getValue(t) != null)
        .toList();
    if (userDimensions.isEmpty) return const FitResult(noUserData: true);

    final sizes = productSizes ?? const <ProductSize>[];
    final evaluated = sizes
        .map((final size) => _evaluate(size, body!, userDimensions, fit, elasticity))
        .where((final e) => e.dimensions.isNotEmpty)
        .toList();

    // The shopper has data, but no published size overlaps it — nothing to
    // advise on, so the banner stays hidden.
    if (evaluated.isEmpty) return const FitResult();

    final cleanMatches = evaluated.where((final e) => e.fitsCleanly).toList();
    if (cleanMatches.isNotEmpty) {
      cleanMatches.sort((final a, final b) => a.centerScore.compareTo(b.centerScore));
      final best = cleanMatches.first;
      final alternative = cleanMatches.length > 1 ? cleanMatches[1] : null;
      return FitResult(
        recommendedSize: best.size.name,
        tryonSizeId: best.size.id,
        matchedTypes: best.matchedTypes,
        alternativeSize: alternative?.size.name,
      );
    }

    // The cap is applied before ranking, not after: the lowest total miss can
    // still be one nobody would wear (a single huge miss beats several small
    // ones on a sum), and rejecting it afterwards would discard the sizes that
    // were actually wearable.
    evaluated.sort((final a, final b) => a.deviationScore.compareTo(b.deviationScore));
    final recommendable = evaluated
        .where((final e) => e.maxDeviation <= EaseTable.maxRecommendableDeviation)
        .toList();
    // The closest size still goes to the try-on: the banner says there is no
    // size for them, and the render is what shows them why.
    if (recommendable.isEmpty) {
      return FitResult(outOfRange: true, tryonSizeId: evaluated.first.size.id);
    }

    final best = recommendable.first;
    return FitResult(
      recommendedSize: best.size.name,
      tryonSizeId: best.size.id,
      caveats: best.caveats,
      matchedTypes: best.matchedTypes,
    );
  }

  static _SizeFit _evaluate(
    final ProductSize size,
    final BodyMeasurements body,
    final List<BodyMeasurementType> userDimensions,
    final ProductFit? fit,
    final ProductElasticity? elasticity,
  ) {
    final dimensions = <_DimensionFit>[];
    for (final type in userDimensions) {
      final bodyValue = body.getValue(type)!;

      final range = size.bodyMeasurementRanges?.getValue(type);
      if (range != null) {
        dimensions.add(_RangeFit(type: type, value: bodyValue, range: range));
        continue;
      }

      final garmentType = type.comparableGarmentType;
      if (garmentType == null) continue;
      final garmentValue = size.garmentMeasurements?.getValue(garmentType);
      if (garmentValue == null) continue;

      final band = EaseTable.bandFor(type, fit, elasticity);
      if (band == null) continue;

      dimensions.add(_EaseFit(type: type, ease: garmentValue - bodyValue, band: band));
    }
    return _SizeFit(size: size, dimensions: dimensions);
  }
}

sealed class _DimensionFit {
  const _DimensionFit({required this.type});

  final BodyMeasurementType type;

  /// How far outside the acceptable band, in the dimension's own unit; zero
  /// when it fits.
  double get deviation;

  /// Distance from the ideal value, used to rank sizes that all fit cleanly.
  double get centerDistance;

  FitDirection get direction;

  bool get inRange => deviation == 0;

  double get weight => FitDimensionWeights.weightFor(type);

  MeasurementCaveat get caveat =>
      MeasurementCaveat(type: type, deviation: deviation, direction: direction);
}

class _EaseFit extends _DimensionFit {
  const _EaseFit({required super.type, required this.ease, required this.band});

  /// Garment measurement minus body measurement, in centimeters.
  final double ease;
  final EaseBand band;

  @override
  double get deviation {
    if (ease < band.min) return band.min - ease;
    if (ease > band.max) return ease - band.max;
    return 0;
  }

  @override
  double get centerDistance => (ease - band.center).abs();

  @override
  FitDirection get direction => ease < band.min ? FitDirection.tight : FitDirection.loose;
}

class _RangeFit extends _DimensionFit {
  const _RangeFit({required super.type, required this.value, required this.range});

  /// The shopper's own value, in the dimension's unit.
  final double value;
  final MeasurementRange range;

  @override
  double get deviation => range.distanceOutside(value);

  @override
  double get centerDistance => (value - range.center).abs();

  @override
  FitDirection get direction =>
      value < range.min ? FitDirection.below : FitDirection.above;
}

class _SizeFit {
  _SizeFit({required this.size, required this.dimensions}) {
    centerScore = dimensions.fold(
      0,
      (final sum, final d) => sum + d.centerDistance * d.weight,
    );
  }

  final ProductSize size;
  final List<_DimensionFit> dimensions;

  bool get fitsCleanly => dimensions.every((final d) => d.inRange);

  /// Weighted distance from the ideal value. Ranks sizes that all fit cleanly.
  double centerScore = 0;

  /// Weighted sum of out-of-range distances. Ranks sizes when none fit cleanly.
  double get deviationScore =>
      dimensions.fold(0, (final sum, final d) => sum + d.deviation * d.weight);

  double get maxDeviation =>
      dimensions.fold(0, (final max, final d) => d.deviation > max ? d.deviation : max);

  List<BodyMeasurementType> get matchedTypes =>
      dimensions.where((final d) => d.inRange).map((final d) => d.type).toList();

  List<MeasurementCaveat> get caveats =>
      dimensions.where((final d) => !d.inRange).map((final d) => d.caveat).toList();
}
