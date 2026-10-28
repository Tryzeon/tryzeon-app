import 'package:json_annotation/json_annotation.dart';

part 'create_product_color_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class CreateProductColorRequest {
  const CreateProductColorRequest({
    required this.productId,
    required this.storeId,
    required this.name,
    required this.imagePaths,
    required this.position,
  });

  final String productId;
  final String storeId;
  final String? name;
  final List<String> imagePaths;
  final int position;

  Map<String, dynamic> toJson() => _$CreateProductColorRequestToJson(this);
}
