import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_subject.freezed.dart';

/// Holds only what the app cannot rebuild: garments are resolved from the
/// pieces at launch, and preferences are read fresh on every run, so
/// regenerating picks up a changed setting.
@freezed
sealed class TryonSubject with _$TryonSubject {
  @Assert('pieces.isNotEmpty')
  factory TryonSubject({
    required final List<OutfitPiece> pieces,
    required final TryonMode mode,
  }) = _TryonSubject;
}
