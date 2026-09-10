import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';

part 'fit_result.freezed.dart';

/// [tight] / [loose] come from an ease comparison against the garment;
/// [below] / [above] from the shopper's value against a store's published
/// body measurement range.
enum FitDirection { tight, loose, below, above }

/// `deviation` is always positive, in the type's own unit (cm, or kg for
/// weight); `direction` records which side of the acceptable band the shopper
/// falls on.
@freezed
sealed class MeasurementCaveat with _$MeasurementCaveat {
  const factory MeasurementCaveat({
    required final BodyMeasurementType type,
    required final double deviation,
    required final FitDirection direction,
  }) = _MeasurementCaveat;
}

@freezed
sealed class FitResult with _$FitResult {
  const factory FitResult({
    final String? recommendedSize,
    final String? tryonSizeId,
    @Default(<MeasurementCaveat>[]) final List<MeasurementCaveat> caveats,

    /// Only includes types compared on both sides, so subtitles like
    /// "{type} fits" stay accurate.
    @Default(<BodyMeasurementType>[]) final List<BodyMeasurementType> matchedTypes,
    final String? alternativeSize,
    @Default(false) final bool outOfRange,
    @Default(false) final bool noUserData,
  }) = _FitResult;
  const FitResult._();

  FitDisplayState get displayState {
    if (noUserData) return FitDisplayState.noUserData;
    if (outOfRange) return FitDisplayState.outOfRange;
    if (caveats.isNotEmpty) return FitDisplayState.caveats;
    if (recommendedSize != null) return FitDisplayState.match;
    return FitDisplayState.unknown;
  }
}

enum FitDisplayState { match, caveats, outOfRange, noUserData, unknown }
