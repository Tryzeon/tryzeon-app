import 'package:flutter/material.dart';
import 'package:tryzeon/core/shared/measurements/entities/size_measurements.dart';
import 'package:tryzeon/core/shared/measurements/presentation/mappers/measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

class ProductSizeEntryController {
  ProductSizeEntryController({
    this.id,
    final String name = '',
    final SizeMeasurements? measurements,
  }) : nameController = TextEditingController(text: name) {
    for (final type in MeasurementType.values) {
      measurementControllers[type] = TextEditingController(
        text: measurements?.getValue(type)?.toString() ?? '',
      );
      offsetControllers[type] = TextEditingController(
        text: measurements?.getOffset(type)?.toString() ?? '0.0',
      );
    }
  }

  factory ProductSizeEntryController.fromProductSize(final ProductSize size) {
    return ProductSizeEntryController(
      id: size.id,
      name: size.name,
      measurements: size.measurements,
    );
  }

  final String? id;
  final TextEditingController nameController;
  final Map<MeasurementType, TextEditingController> measurementControllers = {};
  final Map<MeasurementType, TextEditingController> offsetControllers = {};

  ProductSize toProductSize(final String? productId, {required final bool isCun}) {
    final Map<String, dynamic> measurementsJson = {};
    final multiplier = isCun ? 3.03 : 1.0;

    for (final type in MeasurementType.values) {
      final valueText = measurementControllers[type]?.text;
      final value = valueText != null && valueText.isNotEmpty
          ? double.tryParse(valueText)
          : null;

      final offsetText = offsetControllers[type]?.text;
      final offset = (offsetText != null ? double.tryParse(offsetText) : null) ?? 0.0;

      if (value != null) {
        measurementsJson[type.name] = value * multiplier;
      }
      measurementsJson['${type.name}_offset'] = offset * multiplier;
    }

    return ProductSize(
      id: id,
      productId: productId,
      name: nameController.text,
      measurements: SizeMeasurements.fromJson(measurementsJson),
    );
  }

  void dispose() {
    nameController.dispose();
    for (final controller in measurementControllers.values) {
      controller.dispose();
    }
    for (final controller in offsetControllers.values) {
      controller.dispose();
    }
  }
}
