import 'package:json_annotation/json_annotation.dart';

part 'tryon_response_dto.g.dart';

/// Server → Client wire response from the `tryon` edge function.
@JsonSerializable(createToJson: false, checked: true)
class TryonResponseDto {
  const TryonResponseDto({this.imageUrl, this.videoUrl});

  factory TryonResponseDto.fromJson(final Map<String, dynamic> json) =>
      _$TryonResponseDtoFromJson(json);

  final String? imageUrl;
  final String? videoUrl;
}
