import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/base64_image_dto.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_garment_dto.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_function_request.g.dart';

@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class TryonFunctionRequest {
  const TryonFunctionRequest({
    required this.generationId,
    required this.mode,
    required this.engine,
    this.garments,
    this.avatar,
    this.baseImage,
    this.scenePrompt,
    this.stylingPrompt,
    this.transitionPrompt,
  });

  final String generationId;
  final TryonMode mode;
  final TryonEngine engine;
  final List<TryonGarmentDto>? garments;
  final Base64ImageDto? avatar;
  final Base64ImageDto? baseImage;
  final String? scenePrompt;
  final String? stylingPrompt;
  final String? transitionPrompt;

  bool get isVideo => mode == TryonMode.video;

  Map<String, dynamic> toJson() => _$TryonFunctionRequestToJson(this);
}
