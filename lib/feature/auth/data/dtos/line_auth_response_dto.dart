import 'package:json_annotation/json_annotation.dart';

part 'line_auth_response_dto.g.dart';

@JsonSerializable(createToJson: false, checked: true)
class LineAuthResponseDto {
  const LineAuthResponseDto({required this.refreshToken});

  factory LineAuthResponseDto.fromJson(final Map<String, dynamic> json) =>
      _$LineAuthResponseDtoFromJson(json);

  final String refreshToken;
}
