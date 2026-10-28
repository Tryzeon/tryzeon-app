import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/product_color/data/collections/product_color_embedded.dart';
import 'package:tryzeon/feature/common/product_color/data/dtos/product_color_dto.dart';
import 'package:tryzeon/feature/common/product_color/data/mappers/product_color_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';

@AutoMappr([
  MapType<ProductColorDto, ProductColor>(
    fields: [
      Field('imageUrls', custom: ProductColorMapprHelper.imageUrlsFromDto),
    ],
  ),
  MapType<ProductColor, ProductColorDto>(),
  MapType<ProductColor, ProductColorEmbedded>(),
  MapType<ProductColorEmbedded, ProductColor>(
    fields: [
      Field('imageUrls', custom: ProductColorMapprHelper.imageUrlsFromEmbedded),
    ],
  ),
])
class ProductColorMappr extends $ProductColorMappr {
  const ProductColorMappr();
}

abstract final class ProductColorMapprHelper {
  static List<String> imageUrlsFromDto(final ProductColorDto source) =>
      source.imagePaths.map(PublicImageUrl.of).toList();

  static List<String> imageUrlsFromEmbedded(
    final ProductColorEmbedded source,
  ) => source.imagePaths.map(PublicImageUrl.of).toList();
}
