import 'package:json_annotation/json_annotation.dart';

part 'delete_images_request.g.dart';

@JsonSerializable(createFactory: false)
class DeleteImagesRequest {
  const DeleteImagesRequest({required this.storeId, required this.keys});

  final String storeId;
  final List<String> keys;

  Map<String, dynamic> toJson() => _$DeleteImagesRequestToJson(this);
}
