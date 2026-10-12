import 'package:json_annotation/json_annotation.dart';

part 'presign_file_dto.g.dart';

@JsonSerializable(createFactory: false)
class PresignFileDto {
  const PresignFileDto({
    required this.contentType,
    required this.contentLength,
  });

  final String contentType;
  final int contentLength;

  Map<String, dynamic> toJson() => _$PresignFileDtoToJson(this);
}
