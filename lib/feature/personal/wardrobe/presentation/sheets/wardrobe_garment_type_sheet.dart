import 'package:flutter/material.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';

class WardrobeGarmentTypeSheet extends StatelessWidget {
  const WardrobeGarmentTypeSheet({super.key, required this.selected});

  final GarmentType selected;

  static Future<GarmentType?> show({
    required final BuildContext context,
    required final GarmentType selected,
  }) {
    return showAppSheet<GarmentType>(
      context: context,
      builder: (final _) => WardrobeGarmentTypeSheet(selected: selected),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppSheet(
      title: '更改類別',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in GarmentType.values)
            ListTile(
              title: Text(type.displayName, style: textTheme.bodyLarge),
              trailing: type == selected
                  ? Icon(Icons.check_rounded, color: colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(type),
            ),
        ],
      ),
    );
  }
}
