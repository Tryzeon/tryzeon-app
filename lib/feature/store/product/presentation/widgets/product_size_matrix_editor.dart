import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/body_measurements/presentation/mappers/body_measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/measurement_guide_button.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/standard_size_label.dart';
import 'package:tryzeon/feature/common/product_size/presentation/mappers/garment_measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/presentation/controllers/product_size_entry_controller.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_size_manager.dart';

// Table geometry: the left column and the cells must share a height to line
// up, so these are fixed rather than sized to content. Every field reserves its
// helper line (see [_fieldDecoration]) so a cell keeps its height and position
// when an error appears beneath it. The label column fits `均碼`, the widest
// standard size label.
const double _labelColumnWidth = 42;
// The visible input box, before the caption line beneath it. Row labels centre
// on this rather than on the whole row.
const double _fieldHeight = 40;
const double _tableGap = AppSpacing.lg;
const double _rowHeight = 62;
const double _headerHeight = AppSpacing.xl;

class ProductSizeMatrixEditor extends HookWidget {
  const ProductSizeMatrixEditor({
    super.key,
    required this.manager,
    required this.visibleTypes,
    this.garmentType,
  });

  final ProductSizeManager manager;

  final List<GarmentMeasurementType> visibleTypes;

  final GarmentType? garmentType;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SizeChipRow(
          manager: manager,
          onAddCustom: () => _promptCustomSize(context, manager),
        ),
        const SizedBox(height: AppSpacing.md),
        if (manager.sizeEntries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: Text(
                  '請先選擇尺寸',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else ...[
          _SubsectionHeader(
            title: '商品尺寸',
            helper: '衣服本身量出來的數字',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (garmentType case final type?)
                  MeasurementGuideButton(garmentType: type),
                _UnitSelector(
                  selectedUnit: manager.selectedUnit,
                  onUnitChanged: manager.changeUnit,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MatrixTable(
            entries: manager.sizeEntries,
            columns: [
              for (final type in visibleTypes)
                _MatrixColumn(
                  label: garmentType?.measurementLabel(type) ?? type.label,
                  width: _MeasurementCell.width,
                  cellBuilder: (final entry) => _MeasurementCell(
                    controller: entry.measurementControllers[type]!,
                    type: type,
                    unit: manager.selectedUnit,
                  ),
                ),
            ],
          ),
          const SizedBox(height: _tableGap),
          const _SubsectionHeader(title: '適合身形', helper: '這個尺寸適合的穿著者範圍'),
          const SizedBox(height: AppSpacing.sm),
          _MatrixTable(
            entries: manager.sizeEntries,
            columns: [
              for (final type in BodyMeasurementType.values)
                _MatrixColumn(
                  label: '${type.label} (${type.quantity.unitSuffix})',
                  width: _RangeCell.width,
                  cellBuilder: (final entry) =>
                      _RangeCell(controllers: entry.rangeControllers[type]!, type: type),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _promptCustomSize(
    final BuildContext context,
    final ProductSizeManager manager,
  ) async {
    final result = await showTextInputDialog(
      context: context,
      title: '新增自訂尺寸',
      okLabel: '新增',
      cancelLabel: '取消',
      textFields: [
        DialogTextField(
          hintText: '例如 4XL、US 10',
          maxLength: 8,
          validator: (final value) {
            final emptyError = AppValidators.validateSizeName(value);
            if (emptyError != null) return emptyError;
            if (manager.hasLabel(value!.trim())) return '已有這個尺寸';
            return null;
          },
        ),
      ],
    );
    final name = result?.firstOrNull;
    if (name != null) manager.addCustom(name);
  }
}

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({required this.selectedUnit, required this.onUnitChanged});

  final MeasurementUnit selectedUnit;
  final ValueChanged<MeasurementUnit> onUnitChanged;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return DropdownButtonHideUnderline(
      child: DropdownButton<MeasurementUnit>(
        value: selectedUnit,
        isDense: true,
        style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        items: MeasurementUnit.values
            .map(
              (final unit) =>
                  DropdownMenuItem(value: unit, child: Text(unit.label.toUpperCase())),
            )
            .toList(),
        onChanged: (final v) {
          if (v != null) onUnitChanged(v);
        },
      ),
    );
  }
}

class _SizeChipRow extends StatelessWidget {
  const _SizeChipRow({required this.manager, required this.onAddCustom});

  final ProductSizeManager manager;
  final VoidCallback onAddCustom;

  @override
  Widget build(final BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final label in StandardSizeLabel.values)
          FilterChip(
            label: Text(label.display),
            selected: manager.isSelected(label),
            showCheckmark: false,
            onSelected: (final _) => manager.toggleStandard(label),
          ),
        for (final custom in manager.customLabels)
          FilterChip(
            label: Text(custom),
            selected: true,
            showCheckmark: false,
            onSelected: (final _) => manager.removeLabel(custom),
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 14),
          label: const Text('自訂'),
          onPressed: onAddCustom,
        ),
      ],
    );
  }
}

class _SubsectionHeader extends StatelessWidget {
  const _SubsectionHeader({required this.title, required this.helper, this.trailing});

  final String title;
  final String helper;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                helper,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _MatrixColumn {
  const _MatrixColumn({
    required this.label,
    required this.width,
    required this.cellBuilder,
  });

  final String label;
  final double width;
  final Widget Function(ProductSizeEntryController entry) cellBuilder;
}

class _MatrixTable extends StatelessWidget {
  const _MatrixTable({required this.entries, required this.columns});

  final List<ProductSizeEntryController> entries;
  final List<_MatrixColumn> columns;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final textScaler = MediaQuery.textScalerOf(context);
    final rowHeight = textScaler.scale(_rowHeight);
    final headerHeight = textScaler.scale(_headerHeight);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _labelColumnWidth,
          child: Column(
            children: [
              SizedBox(height: headerHeight),
              for (final entry in entries)
                SizedBox(
                  key: ObjectKey(entry),
                  height: rowHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        height: textScaler.scale(_fieldHeight),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            entry.label,
                            style: textTheme.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Row(
                    children: [
                      for (final column in columns)
                        _HeaderCell(label: column.label, width: column.width),
                    ],
                  ),
                ),
                for (final entry in entries)
                  SizedBox(
                    key: ObjectKey(entry),
                    height: rowHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (final column in columns) column.cellBuilder(entry)],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _MeasurementCell extends StatelessWidget {
  const _MeasurementCell({
    required this.controller,
    required this.type,
    required this.unit,
  });

  final TextEditingController controller;
  final GarmentMeasurementType type;
  final MeasurementUnit unit;

  // The box fits the longest error caption (`100–250 cm`); any narrower and it
  // ellipsizes.
  static const double _fieldWidth = 64;
  static const double _padding = AppSpacing.sm;
  static const double width = _fieldWidth + _padding * 2;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _padding,
          vertical: AppSpacing.xs,
        ),
        child: TextFormField(
          controller: controller,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'))],
          validator: (final value) => AppValidators.validateRange(
            value,
            min: type.minCm,
            max: type.maxCm,
            unitSuffix: 'cm',
            scale: unit.toCmFactor,
            compact: true,
          ),
          decoration: _fieldDecoration(context),
        ),
      ),
    );
  }
}

const TextStyle _captionStyle = TextStyle(fontSize: 9, height: 1.1);

InputDecoration _fieldDecoration(final BuildContext context, {final String? hint}) {
  final theme = Theme.of(context);
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxs,
      vertical: AppSpacing.sm,
    ),
    helperText: ' ',
    helperStyle: _captionStyle,
    errorStyle: _captionStyle,
    errorMaxLines: 1,
  );
}

class _RangeCell extends StatelessWidget {
  const _RangeCell({required this.controllers, required this.type});

  final RangeEntryControllers controllers;
  final BodyMeasurementType type;

  // Each bound fits a four-digit value; the dash between them sits in a gap
  // narrower than the padding between cells so the pair reads as one column.
  static const double _boundWidth = 46;
  static const double _boundGap = AppSpacing.smMd;
  static const double _padding = AppSpacing.sm;
  static const double width = _boundWidth * 2 + _boundGap + _padding * 2;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _padding,
          vertical: AppSpacing.xs,
        ),
        child: FormField<void>(
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          validator: (final _) => _validate(),
          builder: (final state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BoundField(
                    controller: controllers.min,
                    width: _boundWidth,
                    hint: '下限',
                    hasError: state.hasError,
                    onChanged: state.didChange,
                  ),
                  SizedBox(
                    width: _boundGap,
                    child: Center(
                      child: Text(
                        '–',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  _BoundField(
                    controller: controllers.max,
                    width: _boundWidth,
                    hint: '上限',
                    hasError: state.hasError,
                    onChanged: state.didChange,
                  ),
                ],
              ),
              _CaptionLine(text: state.errorText, color: theme.colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }

  String? _validate() {
    final minText = controllers.min.text.trim();
    final maxText = controllers.max.text.trim();
    if (minText.isEmpty && maxText.isEmpty) return null;
    if (minText.isEmpty) return '請填下限';
    if (maxText.isEmpty) return '請填上限';
    final unit = type.quantity.unitSuffix;
    for (final text in [minText, maxText]) {
      final error = AppValidators.validateRange(
        text,
        min: type.min,
        max: type.max,
        unitSuffix: unit,
        compact: true,
      );
      if (error != null) return '需在 $error';
    }
    if (double.parse(maxText) < double.parse(minText)) return '上限需大於下限';
    return null;
  }
}

/// Reserves the same line the garment cells reserve through their helper text,
/// so the two tables' rows line up whether or not anything is shown.
class _CaptionLine extends StatelessWidget {
  const _CaptionLine({required this.text, required this.color});

  final String? text;
  final Color color;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        text ?? ' ',
        style: _captionStyle.copyWith(color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _BoundField extends StatelessWidget {
  const _BoundField({
    required this.controller,
    required this.width,
    required this.hint,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final double width;
  final String hint;
  final bool hasError;
  final ValueChanged<void> onChanged;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final errorBorder = theme.inputDecorationTheme.errorBorder;

    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'))],
        onChanged: (final _) => onChanged(null),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.sm,
          ),
          enabledBorder: hasError ? errorBorder : null,
          focusedBorder: hasError ? theme.inputDecorationTheme.focusedErrorBorder : null,
        ),
      ),
    );
  }
}
