import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/sheets/measurement_guide_sheet.dart';

class MeasurementGuideButton extends StatelessWidget {
  const MeasurementGuideButton({super.key, this.garmentType});

  final GarmentType? garmentType;

  @override
  Widget build(final BuildContext context) {
    return TextButton.icon(
      onPressed: () => MeasurementGuideSheet.show(
        context: context,
        garmentType: garmentType,
      ),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      icon: const Icon(Icons.straighten_rounded, size: 16),
      label: const Text('測量方式'),
    );
  }
}
