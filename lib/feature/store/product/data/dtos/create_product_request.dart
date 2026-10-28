import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_draft_dto.dart';

part 'create_product_request.g.dart';

/// The id is generated client-side (UUID v4) and decides the R2 image path.
/// [draft] is flattened into the same row by [toJson].
@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class CreateProductRequest {
  const CreateProductRequest({
    required this.id,
    required this.storeId,
    required this.draft,
  });

  final String id;
  final String storeId;
  @JsonKey(includeToJson: false)
  final ProductDraftDto draft;

  Map<String, dynamic> toJson() => {
    ..._$CreateProductRequestToJson(this),
    ...draft.toJson(),
  };
}
