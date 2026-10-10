import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_subject.freezed.dart';

/// Holds only what the app cannot rebuild: garments are resolved from the
/// pieces at launch, and the avatar and preferences are read fresh on every
/// run, so regenerating picks up a changed setting.
@freezed
sealed class TryonSubject with _$TryonSubject {
  @Assert('pieces.isNotEmpty')
  factory TryonSubject.generate({
    required final List<OutfitPiece> pieces,
    required final TryonMode mode,
  }) = TryonSubjectGenerate;

  /// An animate request carries no garments, so [origin] is the only thing that
  /// can say what the video shows.
  const factory TryonSubject.animated({
    required final String baseImageUrl,
    required final TryonSubject origin,
  }) = TryonSubjectAnimated;

  const TryonSubject._();

  TryonMode get mode => switch (this) {
    TryonSubjectGenerate(:final mode) => mode,
    TryonSubjectAnimated() => TryonMode.video,
  };

  List<OutfitPiece> get pieces => switch (this) {
    TryonSubjectGenerate(:final pieces) => pieces,
    TryonSubjectAnimated(:final origin) => origin.pieces,
  };
}
