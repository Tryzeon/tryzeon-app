import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/presentation/widgets/image_placeholder.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';

class ProductColorSwatches extends HookWidget {
  const ProductColorSwatches({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelected,
    this.inset = 0,
  });

  static const double _swatchSize = 56;
  static const double _ringGap = AppStroke.medium;
  static const double _ringWidth = AppStroke.regular;
  static const double _ringInset = _ringGap + _ringWidth;
  static const double _slotSize = _swatchSize + 2 * _ringInset;
  static const double _gap = AppSpacing.xs;

  final List<ProductColor> colors;
  final ProductColor selected;
  final ValueChanged<ProductColor> onSelected;

  /// Horizontal inset of the label and of the list's ends, so the list itself
  /// can scroll edge to edge while its first swatch lines up with the label.
  final double inset;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = selected.name;
    final listPadding = (inset - _ringInset).clamp(0.0, inset);
    final controller = useScrollController();
    final decodeWidth = (_swatchSize * MediaQuery.devicePixelRatioOf(context))
        .round();

    // A deep link may open on a colour past the viewport; centre it once on
    // arrival, while a tapped swatch is already in view.
    useEffect(() {
      final index = colors.indexWhere((final c) => c.id == selected.id);
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (index <= 0 || !controller.hasClients) return;
        final position = controller.position;
        final centre =
            listPadding +
            index * (_slotSize + _gap) +
            (_slotSize - position.viewportDimension) / 2;
        controller.jumpTo(
          centre.clamp(position.minScrollExtent, position.maxScrollExtent),
        );
      });
      return null;
    }, const []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name != null) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        SizedBox(
          height: _slotSize,
          child: ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: listPadding),
            itemCount: colors.length,
            separatorBuilder: (final _, final _) => const SizedBox(width: _gap),
            itemBuilder: (final context, final index) {
              final color = colors[index];
              final isSelected = color.id == selected.id;
              return GestureDetector(
                key: Key('color-swatch-${color.id}'),
                onTap: () => onSelected(color),
                child: Container(
                  padding: const EdgeInsets.all(_ringGap),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppRadius.button + _ringInset,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: _ringWidth,
                    ),
                  ),
                  child: Container(
                    width: _swatchSize,
                    height: _swatchSize,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.buttonAll,
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: AppStroke.thin,
                      ),
                    ),
                    child: switch (color.imageUrls.firstOrNull) {
                      final url? => CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        memCacheWidth: decodeWidth,
                      ),
                      null => const ImagePlaceholder(),
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
