import 'package:json_annotation/json_annotation.dart';

part 'tryon_report_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class TryonReportRequest {
  const TryonReportRequest({required this.tryonGenerationId});

  final String tryonGenerationId;

  Map<String, dynamic> toJson() => _$TryonReportRequestToJson(this);
}
