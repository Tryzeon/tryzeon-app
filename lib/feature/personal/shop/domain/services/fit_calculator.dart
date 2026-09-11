import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/ease_table.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/fit_dimension_weights.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/garment_fit_dimension.dart';

/// For every published size it judges each body dimension the shopper has
/// recorded against the body range that size fits, and decides whether the
/// shopper falls inside, below, or above it.
///
/// The range comes from one of two places. If the store published a wearer
/// range for the dimension, that is the range — the store knows its own cut
/// better than a generic ease table. Otherwise, if the dimension has a garment
/// counterpart, the range is derived from the garment measurement and the
/// expected ease band. Dimensions with neither are skipped rather than
/// guessed, so a size judged on chest alone says so ("chest fits") instead of
/// implying a full-body match.
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
    if (body == null || userDimensions.isEmpty) {
      return const FitResult(noUserData: true);
    }

    final sizes = productSizes ?? const <ProductSize>[];
    final evaluated = sizes
        .map((final size) => _evaluate(size, body, userDimensions, fit, elasticity))
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
      final range =
          size.bodyMeasurementRanges?.getValue(type) ??
          _derivedBodyRange(size, type, fit, elasticity);
      if (range == null) continue;
      dimensions.add(
        _DimensionFit(type: type, value: body.getValue(type)!, range: range),
      );
    }
    return _SizeFit(size: size, dimensions: dimensions);
  }

  static MeasurementRange? _derivedBodyRange(
    final ProductSize size,
    final BodyMeasurementType type,
    final ProductFit? fit,
    final ProductElasticity? elasticity,
  ) {
    final garmentType = type.comparableGarmentType;
    if (garmentType == null) return null;
    final garmentValue = size.garmentMeasurements?.getValue(garmentType);
    if (garmentValue == null) return null;
    return EaseTable.bandFor(type, fit, elasticity)?.toBodyRange(garmentValue);
  }
}

class _DimensionFit {
  const _DimensionFit({required this.type, required this.value, required this.range});

  final BodyMeasurementType type;

  /// The shopper's own value, in the dimension's unit.
  final double value;
  final MeasurementRange range;

  /// How far outside the range, in the dimension's own unit; zero when it fits.
  double get deviation => range.distanceOutside(value);

  /// Distance from the ideal value, used to rank sizes that all fit cleanly.
  double get centerDistance => (value - range.center).abs();

  FitDirection get direction =>
      value < range.min ? FitDirection.below : FitDirection.above;

  bool get inRange => deviation == 0;

  double get weight => FitDimensionWeights.weightFor(type);

  MeasurementCaveat get caveat =>
      MeasurementCaveat(type: type, deviation: deviation, direction: direction);
}

class _SizeFit {
  const _SizeFit({required this.size, required this.dimensions});

  final ProductSize size;
  final List<_DimensionFit> dimensions;

  bool get fitsCleanly => dimensions.every((final d) => d.inRange);

  /// Weighted distance from the ideal value. Ranks sizes that all fit cleanly.
  double get centerScore =>
      dimensions.fold(0, (final sum, final d) => sum + d.centerDistance * d.weight);

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
