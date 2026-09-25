import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'tryon.freezed.dart';

@freezed
sealed class TryonParams with _$TryonParams {
  const factory TryonParams({
    required final String requestId,
    required final TryonSubject subject,
    required final TryonPreferences preferences,
    final String? customAvatarUrl,
  }) = _TryonParams;
}

class Tryon {
  Tryon({
    required final TryonRepository tryonRepository,
    required final TryonMediaRepository mediaRepository,
  }) : _tryonRepository = tryonRepository,
       _mediaRepository = mediaRepository;

  final TryonRepository _tryonRepository;
  final TryonMediaRepository _mediaRepository;

  Future<Result<TryonResult, Failure>> call(final TryonParams params) async {
    final request = await _buildRequest(params);
    if (request.isFailure) return Err(request.getError()!);
    return _tryonRepository.tryon(request.get()!);
  }

  Future<Result<TryonRequest, Failure>> _buildRequest(final TryonParams params) async {
    final preferences = params.preferences;

    switch (params.subject) {
      case TryonSubjectAnimated(:final baseImageUrl):
        final image = await _loadRemoteBase64(baseImageUrl);
        if (image.isFailure) return Err(image.getError()!);

        return Ok(
          TryonRequest.animate(
            requestId: params.requestId,
            baseImageBase64: image.get()!,
            transitionPrompt: preferences.transitionPrompt,
            engine: preferences.engine,
          ),
        );

      case TryonSubjectGenerate(:final pieces, :final mode):
        final garments = await _garmentsFor(pieces);
        if (garments.isFailure) return Err(garments.getError()!);

        // Sending none makes the backend fall back to the profile photo.
        String? avatarBase64;
        final customAvatarUrl = params.customAvatarUrl;
        if (customAvatarUrl != null && customAvatarUrl.isNotEmpty) {
          final loaded = await _loadRemoteBase64(customAvatarUrl);
          if (loaded.isFailure) return Err(loaded.getError()!);
          avatarBase64 = loaded.get();
        }

        return Ok(
          TryonRequest.generate(
            requestId: params.requestId,
            garments: garments.get()!,
            mode: mode,
            avatarBase64: avatarBase64,
            scenePrompt: preferences.scenePrompt,
            stylingPrompt: preferences.stylingPrompt,
            transitionPrompt: mode == TryonMode.video
                ? preferences.transitionPrompt
                : null,
            engine: preferences.engine,
          ),
        );
    }
  }

  /// Local photos are read here, at launch, so a regenerate re-reads the file
  /// instead of every gallery entry holding a base64 copy.
  Future<Result<List<TryonGarment>, Failure>> _garmentsFor(
    final List<OutfitPiece> pieces,
  ) async {
    final garments = <TryonGarment>[];
    for (final piece in pieces) {
      switch (piece) {
        case OutfitPieceWardrobe() || OutfitPieceProduct():
          garments.add(piece.garment!);
        case OutfitPieceLocal(:final path):
          final bytes = await _mediaRepository.loadLocalImageBytes(path);
          if (bytes.isFailure) return Err(bytes.getError()!);
          garments.add(TryonGarment.images(base64Images: [base64Encode(bytes.get()!)]));
      }
    }
    return Ok(garments);
  }

  Future<Result<String, Failure>> _loadRemoteBase64(final String url) async {
    final bytes = await _mediaRepository.loadImageBytes(url);
    if (bytes.isFailure) return Err(bytes.getError()!);
    return Ok(base64Encode(bytes.get()!));
  }
}
