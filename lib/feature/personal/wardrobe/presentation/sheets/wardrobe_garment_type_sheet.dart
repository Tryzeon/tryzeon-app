import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';

class WardrobeGarmentTypeSheet extends StatelessWidget {
  const WardrobeGarmentTypeSheet({super.key, required this.selected});

  final GarmentType selected;

  static Future<GarmentType?> show({
    required final BuildContext context,
    required final GarmentType selected,
  }) {
    return showModalBottomSheet<GarmentType>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (final _) => WardrobeGarmentTypeSheet(selected: selected),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text('更改類別', style: textTheme.titleMedium),
          ),
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
