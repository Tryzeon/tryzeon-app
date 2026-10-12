import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_size_draft_dto.dart';

part 'create_product_size_request.g.dart';

/// [size] is flattened into the same row by [toJson].
@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class CreateProductSizeRequest {
  const CreateProductSizeRequest({required this.productId, required this.size});

  final String productId;
  @JsonKey(includeToJson: false)
  final ProductSizeDraftDto size;

  Map<String, dynamic> toJson() => {
    ..._$CreateProductSizeRequestToJson(this),
    ...size.toJson(),
  };
}
