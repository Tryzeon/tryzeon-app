import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/standard_size_label.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

class ProductSizeEntryController {
  ProductSizeEntryController({
    required this.label,
    this.id,
    final GarmentMeasurements? garmentMeasurements,
  }) {
    for (final type in GarmentMeasurementType.values) {
      measurementControllers[type] = TextEditingController(
        text: garmentMeasurements?.getValue(type)?.toString() ?? '',
      );
    }
  }

  factory ProductSizeEntryController.fromProductSize(final ProductSize size) {
    return ProductSizeEntryController(
      id: size.id,
      label: size.name,
      garmentMeasurements: size.garmentMeasurements,
    );
  }

  final String? id;
  final String label;

  final Map<GarmentMeasurementType, TextEditingController> measurementControllers = {};

  String get matchKey => StandardSizeLabel.matchKeyOf(label);

  void applyParsed(final ParsedSize parsed, {required final MeasurementUnit targetUnit}) {
    String format(final double v) => v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

    for (final entry in parsed.garmentMeasurements.entries) {
      final m = entry.value;
      final factor = m.unit.toCmFactor / targetUnit.toCmFactor;
      measurementControllers[entry.key]?.text = format(m.value * factor);
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

  SizeItem toSizeItem({
    required final MeasurementUnit unit,
    required final List<GarmentMeasurementType> visibleTypes,
  }) {
    final garmentMeasurements = _buildMeasurements(
      unit: unit,
      visibleTypes: visibleTypes,
    );
    final sizeId = id;

    return sizeId == null
        ? SizeItem.newSize(name: label, garmentMeasurements: garmentMeasurements)
        : SizeItem.existing(
            id: sizeId,
            name: label,
            garmentMeasurements: garmentMeasurements,
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
      controller.text = (value * factor)
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '');
    }

    measurementControllers.values.forEach(convert);
  }

  void dispose() {
    for (final controller in measurementControllers.values) {
      controller.dispose();
    }
  }
}
