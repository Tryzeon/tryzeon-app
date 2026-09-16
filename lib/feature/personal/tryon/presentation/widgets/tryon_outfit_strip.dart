import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_thumbnail.dart';

class TryonOutfitStrip extends StatelessWidget {
  const TryonOutfitStrip({super.key, required this.pieces, required this.onTap});

  static const double _thumb = 28;
  static const double _overlap = 8;

  final List<OutfitPiece> pieces;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      key: const Key('tryon-outfit-strip'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppSpacing.xxl,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _thumb + (pieces.length - 1) * (_thumb - _overlap),
                height: _thumb,
                child: Stack(
                  children: [
                    for (var i = 0; i < pieces.length; i++)
                      Positioned(
                        left: i * (_thumb - _overlap),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.onPrimary.withValues(
                                alpha: AppOpacity.medium,
                              ),
                              width: AppStroke.thin,
                            ),
                          ),
                          child: ClipOval(
                            child: OutfitPieceThumbnail(
                              piece: pieces[i],
                              size: _thumb,
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${pieces.length} 件',
                style: textTheme.labelMedium?.copyWith(color: colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
