import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/presentation/widgets/pinch_to_zoom.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_label.dart';

class OutfitPhotoDetailPage extends StatelessWidget {
  const OutfitPhotoDetailPage({super.key, required this.path});

  final String path;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainer.withValues(
                alpha: AppOpacity.overlay,
              ),
              foregroundColor: colorScheme.onSurface,
            ),
            onPressed: context.pop,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ColoredBox(
              color: colorScheme.surfaceContainerLow,
              child: PinchToZoom(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (final context, final error, final stackTrace) => Icon(
                    Icons.image_not_supported_outlined,
                    size: AppSpacing.xxl,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              MediaQuery.paddingOf(context).bottom +
                  AppSpacing.bottomNavBarOverlap +
                  AppSpacing.md,
            ),
            child: Chip(label: Text(OutfitPiece.local(path: path).typeLabel)),
          ),
        ],
      ),
    );
  }
}
