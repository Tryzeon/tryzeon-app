import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';

part 'parse_size_voice_request.g.dart';

@JsonSerializable(createFactory: false)
class ParseSizeVoiceRequest {
  const ParseSizeVoiceRequest({
    required this.audioBase64,
    required this.mimeType,
    required this.currentUnit,
  });

  final String audioBase64;
  final String mimeType;
  final MeasurementUnit currentUnit;

  Map<String, dynamic> toJson() => _$ParseSizeVoiceRequestToJson(this);
}
