import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/base64_image_dto.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_garment_dto.dart';
import 'package:tryzeon/feature/personal/tryon/data/mappers/tryon_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';

@AutoMappr([
  MapType<TryonRequest, TryonFunctionRequest>(
    fields: [
      Field('generationId', from: 'requestId'),
      Field('garments', custom: TryonMapprHelper.garmentsToDto),
    ],
  ),
])
class TryonMappr extends $TryonMappr {
  const TryonMappr();
}

class TryonMapprHelper {
  static List<TryonGarmentDto> garmentsToDto(final TryonRequest source) => [
    for (final garment in source.garments)
      switch (garment) {
        TryonGarmentProduct(:final productId, :final sizeId, :final colorId) =>
          TryonProductGarmentDto(
            productId: productId,
            sizeId: sizeId,
            colorId: colorId,
          ),
        TryonGarmentWardrobe(:final wardrobeItemId) => TryonWardrobeGarmentDto(
          wardrobeItemId: wardrobeItemId,
        ),
        TryonGarmentImages(:final base64Images) => TryonImagesGarmentDto(
          images: base64Images.map(Base64ImageDto.new).toList(),
        ),
      },
  ];
}
