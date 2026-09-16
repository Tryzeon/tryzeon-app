import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/coordinators/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/outfit_pieces_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/outfit_tray_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';

bool outfitHasLivePiece(final Set<String>? wardrobeIds, final TryonGalleryEntry entry) =>
    entry.pieces.any((final p) => p.isLiveIn(wardrobeIds));

Future<void> showOutfitPieces(
  final BuildContext context,
  final WidgetRef ref,
  final TryonGalleryEntry entry,
) async {
  final edit = await OutfitPiecesSheet.show(context, entry: entry);
  if (!edit || !context.mounted) return;
  await editOutfit(context, ref, entry);
}

Future<void> editOutfit(
  final BuildContext context,
  final WidgetRef ref,
  final TryonGalleryEntry entry,
) async {
  final tray = ref.read(outfitTrayProvider.notifier);
  if (ref.read(outfitTrayProvider).pieces.isNotEmpty) {
    final confirmed = await showAppOkCancelDialog(
      context: context,
      title: '取代目前的搭配？',
      message: '這套搭配會取代搭配盤裡的衣物。',
      okLabel: '取代',
      cancelLabel: '取消',
    );
    if (confirmed != OkCancelResult.ok || !context.mounted) return;
  }
  tray.replaceWith(entry.pieces);
  ref.read(tryonCoordinatorProvider).navigateTo(PersonalTab.wardrobe);
}
