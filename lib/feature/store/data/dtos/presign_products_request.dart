import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/store/data/dtos/presign_file_dto.dart';

part 'presign_products_request.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class PresignProductsRequest {
  const PresignProductsRequest({
    required this.storeId,
    required this.productId,
    required this.files,
  });

  final String storeId;
  final String productId;
  final List<PresignFileDto> files;

  Map<String, dynamic> toJson() => _$PresignProductsRequestToJson(this);
}
