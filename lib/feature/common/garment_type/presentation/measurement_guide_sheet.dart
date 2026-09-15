import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_measurement_guide.dart';

const double _guideAspectRatio = 1;
const double _maxGuideHeightFraction = 0.7;
const double _maxGuideZoom = 4;

class MeasurementGuideSheet extends HookWidget {
  const MeasurementGuideSheet({super.key, required this.garmentType});

  final GarmentType garmentType;

  static Future<void> show({
    required final BuildContext context,
    required final GarmentType garmentType,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final context) => MeasurementGuideSheet(garmentType: garmentType),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final assets = garmentType.measurementGuideAssets;
    final pageController = usePageController();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.straighten_rounded, color: colorScheme.onSurface, size: 24),
                  const SizedBox(width: AppSpacing.smMd),
                  Text('${garmentType.displayName}測量方式', style: textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * _maxGuideHeightFraction,
                ),
                child: AspectRatio(
                  aspectRatio: _guideAspectRatio,
                  child: PhotoViewGallery.builder(
                    pageController: pageController,
                    itemCount: assets.length,
                    backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                    builder: (final context, final index) => PhotoViewGalleryPageOptions(
                      imageProvider: AssetImage(assets[index]),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.contained * _maxGuideZoom,
                    ),
                  ),
                ),
              ),
            ),
            if (assets.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: SmoothPageIndicator(
                  controller: pageController,
                  count: assets.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: AppSpacing.sm,
                    dotWidth: AppSpacing.sm,
                    spacing: AppSpacing.sm,
                    activeDotColor: colorScheme.primary,
                    dotColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
