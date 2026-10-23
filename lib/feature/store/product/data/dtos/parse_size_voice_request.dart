import 'package:json_annotation/json_annotation.dart';

part 'parse_size_voice_request.g.dart';

@JsonSerializable(createFactory: false)
class ParseSizeVoiceRequest {
  const ParseSizeVoiceRequest({
    required this.audioBase64,
    required this.mimeType,
  });

  final String audioBase64;
  final String mimeType;

  Map<String, dynamic> toJson() => _$ParseSizeVoiceRequestToJson(this);
}
