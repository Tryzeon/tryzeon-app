import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';

part 'outfit_tray_controller.freezed.dart';
part 'outfit_tray_controller.g.dart';

enum OutfitPieceStatus { absent, held, heldInOtherColor }

@freezed
sealed class OutfitTrayState with _$OutfitTrayState {
  const factory OutfitTrayState({
    @Default(false) final bool isOpen,
    @Default(<OutfitPiece>[]) final List<OutfitPiece> pieces,
    @Default(0) final int rejectedCount,
  }) = _OutfitTrayState;

  const OutfitTrayState._();

  bool get isFull => pieces.length >= AppConstants.maxTryonGarments;

  OutfitPieceStatus statusOf(final OutfitPiece piece) {
    final held = pieces.firstWhereOrNull((final p) => p.id == piece.id);
    if (held == null) return OutfitPieceStatus.absent;
    return held.colorId == piece.colorId
        ? OutfitPieceStatus.held
        : OutfitPieceStatus.heldInOtherColor;
  }

  bool holds(final OutfitPiece piece) =>
      statusOf(piece) == OutfitPieceStatus.held;
}

/// [rejectedCount] only ever grows: the dock listens to it to play the cap
/// feedback once per refused add.
@Riverpod(name: 'outfitTrayProvider', keepAlive: true)
class OutfitTrayController extends _$OutfitTrayController {
  @override
  OutfitTrayState build() {
    ref.watch(isAuthenticatedProvider);
    return const OutfitTrayState();
  }

  void open() => state = state.copyWith(isOpen: true);

  void close() => state = state.copyWith(isOpen: false, pieces: const []);

  void add(final OutfitPiece piece) {
    switch (state.statusOf(piece)) {
      case OutfitPieceStatus.held:
        return;
      case OutfitPieceStatus.heldInOtherColor:
        state = state.copyWith(
          pieces: [for (final p in state.pieces) p.id == piece.id ? piece : p],
        );
      case OutfitPieceStatus.absent when state.isFull:
        state = state.copyWith(rejectedCount: state.rejectedCount + 1);
      case OutfitPieceStatus.absent:
        state = state.copyWith(pieces: [...state.pieces, piece]);
    }
  }

  void remove(final String id) {
    state = state.copyWith(
      pieces: state.pieces.where((final p) => p.id != id).toList(),
    );
  }

  void toggle(final OutfitPiece piece) =>
      state.holds(piece) ? remove(piece.id) : add(piece);

  void replaceWith(final List<OutfitPiece> pieces) {
    state = state.copyWith(
      isOpen: true,
      pieces: pieces.take(AppConstants.maxTryonGarments).toList(),
    );
  }

  List<OutfitPiece> launch() {
    final pieces = state.pieces;
    state = state.copyWith(isOpen: false, pieces: const []);
    return pieces;
  }
}
