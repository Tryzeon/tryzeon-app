import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/measurement/presentation/formatters/measurement_value_format.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/standard_size_label.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

String _formatValue(final double? value) =>
    value == null ? '' : formatMeasurementValue(value);

class RangeEntryControllers {
  RangeEntryControllers({final MeasurementRange? initial})
    : min = TextEditingController(text: _formatValue(initial?.min)),
      max = TextEditingController(text: _formatValue(initial?.max));

  final TextEditingController min;
  final TextEditingController max;

  bool get isEmpty => min.text.isEmpty && max.text.isEmpty;

  MeasurementRange? toRange() {
    final lower = double.tryParse(min.text);
    final upper = double.tryParse(max.text);
    if (lower == null || upper == null) return null;
    return MeasurementRange(min: lower, max: upper);
  }

  void apply(final MeasurementRange range) {
    min.text = _formatValue(range.min);
    max.text = _formatValue(range.max);
  }

  void dispose() {
    min.dispose();
    max.dispose();
  }
}

class ProductSizeEntryController {
  ProductSizeEntryController({
    required this.label,
    this.id,
    final GarmentMeasurements? garmentMeasurements,
    final BodyMeasurementRanges? bodyMeasurementRanges,
  }) {
    for (final type in GarmentMeasurementType.values) {
      measurementControllers[type] = TextEditingController(
        text: _formatValue(garmentMeasurements?.getValue(type)),
      );
    }
    for (final type in bodyMeasurementRangeTypes) {
      rangeControllers[type] = RangeEntryControllers(
        initial: bodyMeasurementRanges?.getValue(type),
      );
    }
  }

  factory ProductSizeEntryController.fromProductSize(final ProductSize size) {
    return ProductSizeEntryController(
      id: size.id,
      label: size.name,
      garmentMeasurements: size.garmentMeasurements,
      bodyMeasurementRanges: size.bodyMeasurementRanges,
    );
  }

  final String? id;
  final String label;

  final Map<GarmentMeasurementType, TextEditingController> measurementControllers = {};

  /// Body measurement ranges are body values in the body type's own unit (cm or kg), so
  /// they stay out of the cm/寸/吋 conversion the garment cells go through.
  final Map<BodyMeasurementType, RangeEntryControllers> rangeControllers = {};

  String get matchKey => StandardSizeLabel.matchKeyOf(label);

  void applyParsed(final ParsedSize parsed, {required final MeasurementUnit targetUnit}) {
    for (final entry in parsed.garmentMeasurements.entries) {
      final m = entry.value;
      final factor = m.unit.toCmFactor / targetUnit.toCmFactor;
      measurementControllers[entry.key]?.text = _formatValue(m.value * factor);
    }
    for (final entry in parsed.bodyMeasurementRanges.entries) {
      rangeControllers[entry.key]?.apply(entry.value);
    }
  }

  double? _parseAndConvert(final String? text, final MeasurementUnit unit) {
    if (text == null || text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) return null;
    return double.parse((value * unit.toCmFactor).toStringAsFixed(1));
  }

  GarmentMeasurements _buildMeasurements({
    required final MeasurementUnit unit,
    required final List<GarmentMeasurementType> visibleTypes,
  }) {
    return GarmentMeasurements.fromValues({
      for (final type in visibleTypes)
        type: _parseAndConvert(measurementControllers[type]?.text, unit),
    });
  }

  BodyMeasurementRanges? _buildBodyMeasurementRanges() {
    final range = BodyMeasurementRanges.fromValues({
      for (final entry in rangeControllers.entries) entry.key: entry.value.toRange(),
    });
    return range.isEmpty ? null : range;
  }

  SizeItem toSizeItem({
    required final MeasurementUnit unit,
    required final List<GarmentMeasurementType> visibleTypes,
  }) {
    final garmentMeasurements = _buildMeasurements(
      unit: unit,
      visibleTypes: visibleTypes,
    );
    final bodyMeasurementRanges = _buildBodyMeasurementRanges();
    final sizeId = id;

    return sizeId == null
        ? SizeItem.newSize(
            name: label,
            garmentMeasurements: garmentMeasurements,
            bodyMeasurementRanges: bodyMeasurementRanges,
          )
        : SizeItem.existing(
            id: sizeId,
            name: label,
            garmentMeasurements: garmentMeasurements,
            bodyMeasurementRanges: bodyMeasurementRanges,
          );
  }

  void convertValues({
    required final MeasurementUnit fromUnit,
    required final MeasurementUnit toUnit,
  }) {
    if (fromUnit == toUnit) return;

    final factor = fromUnit.toCmFactor / toUnit.toCmFactor;

    void convert(final TextEditingController controller) {
      final value = double.tryParse(controller.text);
      if (value == null) return;
      controller.text = _formatValue(value * factor);
    }

    measurementControllers.values.forEach(convert);
  }

  void dispose() {
    for (final controller in measurementControllers.values) {
      controller.dispose();
    }
    for (final controller in rangeControllers.values) {
      controller.dispose();
    }
  }
}
