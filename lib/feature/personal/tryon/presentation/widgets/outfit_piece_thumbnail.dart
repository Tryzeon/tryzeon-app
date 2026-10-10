import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

class OutfitPieceThumbnail extends ConsumerWidget {
  const OutfitPieceThumbnail({
    super.key,
    required this.piece,
    required this.size,
    required this.borderRadius,
  });

  final OutfitPiece piece;
  final double size;
  final BorderRadius borderRadius;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ImageProvider? image = switch (piece) {
      OutfitPieceWardrobe(:final imagePath) =>
        ref
            .watch(wardrobeItemImageProvider(imagePath))
            .whenOrNull(data: FileImage.new),
      OutfitPieceProduct(:final imageUrl) =>
        imageUrl.isEmpty ? null : CachedNetworkImageProvider(imageUrl),
      OutfitPieceLocal(:final path) => FileImage(File(path)),
    };

    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: SizedBox.square(
          dimension: size,
          child: image == null
              ? null
              : Image(
                  image: image,
                  fit: BoxFit.cover,
                  errorBuilder: (final _, final _, final _) =>
                      const SizedBox.shrink(),
                ),
        ),
      ),
    );
  }
}
