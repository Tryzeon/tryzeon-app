import 'package:json_annotation/json_annotation.dart';

part 'base64_image_dto.g.dart';

@JsonSerializable(createFactory: false)
class Base64ImageDto {
  const Base64ImageDto(this.base64);

  final String base64;

  Map<String, dynamic> toJson() => _$Base64ImageDtoToJson(this);
}
