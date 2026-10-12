import 'package:json_annotation/json_annotation.dart';

part 'image_analysis_request.g.dart';

@JsonSerializable(createFactory: false)
class ImageAnalysisRequest {
  const ImageAnalysisRequest({required this.base64});

  final String base64;

  Map<String, dynamic> toJson() => _$ImageAnalysisRequestToJson(this);
}
