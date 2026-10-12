import 'package:json_annotation/json_annotation.dart';

part 'presign_logo_request.g.dart';

@JsonSerializable(createFactory: false)
class PresignLogoRequest {
  const PresignLogoRequest({
    required this.storeId,
    required this.contentType,
    required this.contentLength,
  });

  final String storeId;
  final String contentType;
  final int contentLength;

  Map<String, dynamic> toJson() => _$PresignLogoRequestToJson(this);
}
