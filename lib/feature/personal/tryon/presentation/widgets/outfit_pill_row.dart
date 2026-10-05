import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/actions/outfit_actions.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/outfit_tray_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_fab.dart';

/// The `搭配` / `試穿` pair every garment detail page shows over its image.
class OutfitPillRow extends ConsumerWidget {
  const OutfitPillRow({super.key, required this.piece});

  final OutfitPiece piece;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isInOutfit = ref.watch(
      outfitTrayProvider.select((final s) => s.contains(piece.id)),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TryonFab(
          icon: isInOutfit ? Icons.check_rounded : Icons.add_rounded,
          label: isInOutfit ? '已加入' : '搭配',
          onTap: () => toggleOutfitPiece(ref, piece),
        ),
        const SizedBox(width: AppSpacing.sm),
        TryonFab(
          label: '試穿',
          onTap: () => triggerOutfitTryon(context, ref, [piece]),
        ),
      ],
    );
  }
}
