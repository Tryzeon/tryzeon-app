import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/body_measurements/presentation/mappers/body_measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/common/measurement/presentation/formatters/measurement_value_format.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/common/product_size/presentation/mappers/garment_measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/common/product_size/presentation/mappers/measurement_range_ui_mapper.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/size_advisor_banner.dart';

/// The body ranges come first: they answer "which one is me" directly, while
/// the garment's own numbers are reference material.
class ProductSizeTable extends StatelessWidget {
  const ProductSizeTable({
    required this.sizes,
    required this.columnTypes,
    required this.fitResult,
    super.key,
  });

  final List<ProductSize> sizes;
  final List<GarmentMeasurementType> columnTypes;
  final FitResult fitResult;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final rangeTypes = bodyMeasurementRangeTypes
        .where(
          (final type) =>
              sizes.any((final s) => s.bodyMeasurementRanges?.getValue(type) != null),
        )
        .toList();
    final garmentTypes = columnTypes
        .where(
          (final type) =>
              sizes.any((final s) => s.garmentMeasurements?.getValue(type) != null),
        )
        .toList();

    final highlight = _RecommendationHighlight.of(fitResult);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('尺寸資訊', style: textTheme.titleMedium),
        if (fitResult.displayState != FitDisplayState.unknown) ...[
          const SizedBox(height: AppSpacing.smMd),
          SizeAdvisorBanner(fitResult: fitResult),
        ],
        if (rangeTypes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('適合身形', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _SizeDataTable(
            sizes: sizes,
            highlight: highlight,
            columns: [
              for (final type in rangeTypes)
                _SizeColumn(
                  label: type.label,
                  cellText: (final size) {
                    final range = size.bodyMeasurementRanges?.getValue(type);
                    return range == null
                        ? '-'
                        : '${range.display} ${type.quantity.unitSuffix}';
                  },
                ),
            ],
          ),
        ],
        if (garmentTypes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('商品尺寸（cm）', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _SizeDataTable(
            sizes: sizes,
            highlight: highlight,
            columns: [
              for (final type in garmentTypes)
                _SizeColumn(
                  label: type.label,
                  cellText: (final size) {
                    final value = size.garmentMeasurements?.getValue(type);
                    return value == null ? '-' : formatMeasurementValue(value);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '* 此尺寸數據可能存在些許誤差',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _RecommendationHighlight {
  const _RecommendationHighlight({required this.sizeName, this.row, this.check});

  factory _RecommendationHighlight.of(final FitResult fitResult) {
    final (Color? row, Color? check) = switch (fitResult.displayState) {
      FitDisplayState.match => (AppColors.fitMatchContainer, AppColors.fitMatch),
      FitDisplayState.caveats => (AppColors.fitCaveatContainer, AppColors.fitCaveat),
      _ => (null, null),
    };
    return _RecommendationHighlight(
      sizeName: fitResult.recommendedSize,
      row: row,
      check: check,
    );
  }

  final String? sizeName;
  final Color? row;
  final Color? check;

  bool matches(final ProductSize size) => sizeName != null && size.name == sizeName;
}

class _SizeColumn {
  const _SizeColumn({required this.label, required this.cellText});

  final String label;
  final String Function(ProductSize size) cellText;
}

class _SizeDataTable extends StatelessWidget {
  const _SizeDataTable({
    required this.sizes,
    required this.columns,
    required this.highlight,
  });

  final List<ProductSize> sizes;
  final List<_SizeColumn> columns;
  final _RecommendationHighlight highlight;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (final context, final constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            columnSpacing: AppSpacing.lg,
            columns: [
              const DataColumn(label: Text('尺寸')),
              for (final column in columns) DataColumn(label: Text(column.label)),
            ],
            rows: [
              for (final size in sizes)
                DataRow(
                  color: highlight.matches(size) && highlight.row != null
                      ? WidgetStateProperty.all(highlight.row!.withValues(alpha: 0.5))
                      : null,
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            size.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: highlight.matches(size)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (highlight.matches(size) && highlight.check != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(Icons.check_rounded, size: 14, color: highlight.check),
                          ],
                        ],
                      ),
                    ),
                    for (final column in columns)
                      DataCell(Text(column.cellText(size), style: textTheme.bodyMedium)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
