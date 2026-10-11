import 'package:json_annotation/json_annotation.dart';

part 'presigned_upload_dto.g.dart';

@JsonSerializable(createToJson: false, checked: true)
class PresignedUploadDto {
  const PresignedUploadDto({required this.key, required this.uploadUrl});

  factory PresignedUploadDto.fromJson(final Map<String, dynamic> json) =>
      _$PresignedUploadDtoFromJson(json);

  final String key;
  final String uploadUrl;
}
