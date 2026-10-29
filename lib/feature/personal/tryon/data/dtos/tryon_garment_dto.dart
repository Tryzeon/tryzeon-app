import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/base64_image_dto.dart';

part 'tryon_garment_dto.g.dart';

sealed class TryonGarmentDto {
  const TryonGarmentDto();

  Map<String, dynamic> toJson();
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class TryonProductGarmentDto extends TryonGarmentDto {
  const TryonProductGarmentDto({
    required this.productId,
    this.sizeId,
    this.colorId,
  });

  final String productId;
  final String? sizeId;
  final String? colorId;

  @override
  Map<String, dynamic> toJson() => _$TryonProductGarmentDtoToJson(this);
}

@JsonSerializable(createFactory: false)
class TryonWardrobeGarmentDto extends TryonGarmentDto {
  const TryonWardrobeGarmentDto({required this.wardrobeItemId});

  final String wardrobeItemId;

  @override
  Map<String, dynamic> toJson() => _$TryonWardrobeGarmentDtoToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class TryonImagesGarmentDto extends TryonGarmentDto {
  const TryonImagesGarmentDto({required this.images});

  final List<Base64ImageDto> images;

  @override
  Map<String, dynamic> toJson() => _$TryonImagesGarmentDtoToJson(this);
}
