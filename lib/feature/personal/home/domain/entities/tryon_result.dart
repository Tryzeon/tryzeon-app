import 'package:freezed_annotation/freezed_annotation.dart';
import 'tryon_mode.dart';

part 'tryon_result.freezed.dart';

@freezed
sealed class TryonResult with _$TryonResult {
  const factory TryonResult({
    final String? imageBase64,
    final String? videoPath,
    @Default(TryOnMode.photo) final TryOnMode mode,
  }) = _TryonResult;
}
