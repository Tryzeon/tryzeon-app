import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_request.freezed.dart';

@freezed
sealed class TryonRequest with _$TryonRequest {
  const factory TryonRequest({
    required final String requestId,
    required final List<TryonGarment> garments,
    required final TryonMode mode,
    required final TryonEngine engine,
    final String? scenePrompt,
    final String? stylingPrompt,
    final String? transitionPrompt,
  }) = _TryonRequest;
}
