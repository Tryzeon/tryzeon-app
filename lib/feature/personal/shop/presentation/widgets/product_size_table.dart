import 'package:flutter/material.dart';
import 'package:tryzeon/core/shared/measurements/presentation/mappers/measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

class ProductSizeTable extends StatelessWidget {
  const ProductSizeTable({required this.sizes, super.key});

  final List<ProductSize> sizes;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('尺寸資訊', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            columns: [
              const DataColumn(label: Text('尺寸')),
              ...MeasurementType.values.map(
                (final type) => DataColumn(label: Text(type.label)),
              ),
            ],
            rows: sizes.map((final size) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(size.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...MeasurementType.values.map((final type) {
                    final measurements = size.measurements;
                    final value = measurements?.getValue(type);
                    return DataCell(Text(value != null ? value.toStringAsFixed(1) : '-'));
                  }),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text('* 此尺寸數據為手工測量，可能存在些許誤差', style: textTheme.bodySmall),
      ],
    );
  }
}
