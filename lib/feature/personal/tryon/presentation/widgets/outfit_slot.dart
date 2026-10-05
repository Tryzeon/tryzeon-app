import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_label.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_thumbnail.dart';

enum OutfitSlotKind { filled, next, later }

class OutfitSlot extends StatelessWidget {
  const OutfitSlot({
    super.key,
    required this.index,
    required this.piece,
    required this.kind,
    required this.onRemove,
  });

  static const double size = 40;

  final int index;
  final OutfitPiece? piece;
  final OutfitSlotKind kind;
  final ValueChanged<String> onRemove;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final piece = this.piece;

    final label = piece?.typeLabel ?? '';

    final box = piece != null
        ? InkWell(
            key: Key('outfit-slot-remove-${piece.id}'),
            onTap: () => onRemove(piece.id),
            borderRadius: AppRadius.buttonAll,
            child: SizedBox(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  OutfitPieceThumbnail(
                    piece: piece,
                    size: size,
                    borderRadius: AppRadius.buttonAll,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: CircleAvatar(
                        radius: AppSpacing.sm,
                        backgroundColor: colorScheme.primary,
                        child: Icon(
                          Icons.close_rounded,
                          size: AppSpacing.smMd,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : SizedBox(
            key: ValueKey('empty-$index'),
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.buttonAll,
                  border: Border.all(
                    color: kind == OutfitSlotKind.next
                        ? colorScheme.outline
                        : colorScheme.outlineVariant,
                    width: AppStroke.thin,
                  ),
                ),
                child: kind == OutfitSlotKind.next
                    ? Icon(
                        Icons.add_rounded,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
          );

    return Column(
      key: Key('outfit-slot-$index'),
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : AppDuration.standard,
          reverseDuration: reduceMotion ? Duration.zero : AppDuration.quick,
          switchInCurve: AppCurves.emphasized,
          switchOutCurve: AppCurves.exit,
          transitionBuilder: (final child, final animation) => AnimatedBuilder(
            animation: animation,
            builder: (final _, final child) {
              final isLeaving = animation.status == AnimationStatus.reverse;
              final scale = isLeaving
                  ? 1.0
                  : lerpDouble(0.8, 1, animation.value)!;
              return Opacity(
                opacity: animation.value,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: child,
          ),
          child: box,
        ),
        SizedBox(
          height: AppSpacing.md,
          child: Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
