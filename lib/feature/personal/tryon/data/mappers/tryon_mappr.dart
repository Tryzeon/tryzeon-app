import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/daily_usage/data/mappers/daily_usage_mappr.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/base64_image_dto.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_garment_dto.dart';
import 'package:tryzeon/feature/personal/tryon/data/mappers/tryon_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';

@AutoMappr(
  [
    MapType<TryonGenerateRequest, TryonFunctionRequest>(
      fields: [
        Field('generationId', from: 'requestId'),
        Field('garments', custom: TryonMapprHelper.garmentsToDto),
      ],
    ),
    MapType<TryonAnimateRequest, TryonFunctionRequest>(
      fields: [
        Field('generationId', from: 'requestId'),
        Field('baseImage', custom: TryonMapprHelper.baseImageToDto),
      ],
    ),
  ],
  includes: [DailyUsageMappr()],
)
class TryonMappr extends $TryonMappr {
  const TryonMappr();
}

class TryonMapprHelper {
  static List<TryonGarmentDto> garmentsToDto(
    final TryonGenerateRequest source,
  ) => [
    for (final garment in source.garments)
      switch (garment) {
        TryonGarmentProduct(:final productId, :final sizeId) =>
          TryonProductGarmentDto(productId: productId, sizeId: sizeId),
        TryonGarmentWardrobe(:final wardrobeItemId) => TryonWardrobeGarmentDto(
          wardrobeItemId: wardrobeItemId,
        ),
        TryonGarmentImages(:final base64Images) => TryonImagesGarmentDto(
          images: base64Images.map(Base64ImageDto.new).toList(),
        ),
      },
  ];

  static Base64ImageDto baseImageToDto(final TryonAnimateRequest source) =>
      Base64ImageDto(source.baseImageBase64);
}
