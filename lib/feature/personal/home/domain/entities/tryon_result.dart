import 'package:freezed_annotation/freezed_annotation.dart';
import 'tryon_mode.dart';

part 'tryon_result.freezed.dart';

@freezed
sealed class TryonResult with _$TryonResult {
  const factory TryonResult({
    required final String id,
    final String? imageBase64,
    final String? videoUrl,
    @Default(false) final bool isLoading,
    @Default(TryOnMode.image) final TryOnMode mode,
  }) = _TryonResult;
}
