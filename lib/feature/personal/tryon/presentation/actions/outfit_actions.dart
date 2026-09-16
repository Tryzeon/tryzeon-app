import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/coordinators/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/outfit_tray_controller.dart';

void toggleOutfitPiece(final WidgetRef ref, final OutfitPiece piece) {
  HapticFeedback.selectionClick();
  ref.read(outfitTrayProvider.notifier)
    ..open()
    ..toggle(piece);
}

/// [beforeLaunch] runs once a mode is chosen, so dismissing the sheet leaves
/// the caller's state untouched.
void triggerOutfitTryon(
  final BuildContext context,
  final WidgetRef ref,
  final List<OutfitPiece> pieces, {
  final VoidCallback? beforeLaunch,
}) {
  HapticFeedback.mediumImpact();
  TryonModeSheet.show(
    context: context,
    onModeSelected: (final mode) {
      beforeLaunch?.call();
      ref.read(tryonCoordinatorProvider).tryonFromOutfit(pieces, mode: mode);
    },
  );
}
