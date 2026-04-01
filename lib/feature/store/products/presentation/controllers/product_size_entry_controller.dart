import 'package:flutter/material.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurements.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

class ProductSizeEntryController {
  ProductSizeEntryController({
    this.id,
    this.createdAt,
    this.updatedAt,
    final String name = '',
    final Measurements? measurements,
  }) : nameController = TextEditingController(text: name) {
    for (final type in MeasurementType.values) {
      measurementControllers[type] = TextEditingController(
        text: measurements?.getValue(type)?.toString() ?? '',
      );

      final offsetValue = measurements?.getOffset(type);
      offsetControllers[type] = TextEditingController(
        text: offsetValue?.toString() ?? '',
      );
    }
  }

  factory ProductSizeEntryController.fromProductSize(final ProductSize size) {
    return ProductSizeEntryController(
      id: size.id,
      createdAt: size.createdAt,
      updatedAt: size.updatedAt,
      name: size.name,
      measurements: size.measurements,
    );
  }

  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TextEditingController nameController;
  final Map<MeasurementType, TextEditingController> measurementControllers = {};
  final Map<MeasurementType, TextEditingController> offsetControllers = {};

  static const double _cunToCmFactor = 3.03; // 1 Cun = 3.03 CM

  double? _parseAndConvert(final String? text, final double multiplier) {
    if (text == null || text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) return null;
    return double.parse((value * multiplier).toStringAsFixed(1));
  }

  Measurements _buildMeasurements({required final bool isCun}) {
    final multiplier = isCun ? _cunToCmFactor : 1.0;

    double? getValue(final MeasurementType type) =>
        _parseAndConvert(measurementControllers[type]?.text, multiplier);

    double? getOffset(final MeasurementType type) =>
        _parseAndConvert(offsetControllers[type]?.text.trim(), multiplier);

    return Measurements(
      height: getValue(MeasurementType.height),
      chest: getValue(MeasurementType.chest),
      waist: getValue(MeasurementType.waist),
      hips: getValue(MeasurementType.hips),
      shoulder: getValue(MeasurementType.shoulder),
      sleeve: getValue(MeasurementType.sleeve),
      heightOffset: getOffset(MeasurementType.height),
      chestOffset: getOffset(MeasurementType.chest),
      waistOffset: getOffset(MeasurementType.waist),
      hipsOffset: getOffset(MeasurementType.hips),
      shoulderOffset: getOffset(MeasurementType.shoulder),
      sleeveOffset: getOffset(MeasurementType.sleeve),
    );
  }

  CreateProductSizeParams toCreateProductSizeParams({required final bool isCun}) {
    return CreateProductSizeParams(
      name: nameController.text,
      measurements: _buildMeasurements(isCun: isCun),
    );
  }

  ProductSize toProductSize(final String productId, {required final bool isCun}) {
    return ProductSize(
      id: id!,
      productId: productId,
      name: nameController.text,
      measurements: _buildMeasurements(isCun: isCun),
      createdAt: createdAt!,
      updatedAt: updatedAt!,
    );
  }

  void convertValues({required final bool toCun}) {
    final factor = toCun ? 1 / _cunToCmFactor : _cunToCmFactor;

    void convert(final TextEditingController controller) {
      final value = double.tryParse(controller.text);
      if (value == null) return;
      controller.text = (value * factor)
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '');
    }

    measurementControllers.values.forEach(convert);
    offsetControllers.values.forEach(convert);
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
