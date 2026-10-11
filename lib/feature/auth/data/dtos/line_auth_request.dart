import 'package:json_annotation/json_annotation.dart';

part 'line_auth_request.g.dart';

@JsonSerializable(createFactory: false)
class LineAuthRequest {
  const LineAuthRequest({required this.idToken, required this.nonce});

  final String idToken;
  final String nonce;

  Map<String, dynamic> toJson() => _$LineAuthRequestToJson(this);
}
