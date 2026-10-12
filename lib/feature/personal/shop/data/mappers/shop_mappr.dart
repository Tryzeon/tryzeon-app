import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/product_size_mappr.dart';
import 'package:tryzeon/feature/common/store/data/mappers/common_store_mappr.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_product_dto.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_store_info_dto.dart';
import 'package:tryzeon/feature/personal/shop/data/mappers/shop_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';

@AutoMappr(
  [
    MapType<ShopProductDto, ShopProduct>(
      fields: [Field('imageUrls', custom: ShopMapprHelper.imageUrlsToEntity)],
    ),
    MapType<ShopStoreInfoDto, ShopStoreInfo>(
      fields: [
        Field('channels', custom: ShopMapprHelper.channelsToEntity),
        Field('logoUrl', custom: ShopMapprHelper.logoUrlToEntity),
      ],
    ),
  ],
  includes: [ProductSizeMappr(), CommonStoreMappr()],
)
class ShopMappr extends $ShopMappr {
  const ShopMappr();
}

class ShopMapprHelper {
  static List<String> imageUrlsToEntity(final ShopProductDto source) =>
      source.imagePaths.map(PublicImageUrl.of).toList();

  static Set<StoreChannel> channelsToEntity(final ShopStoreInfoDto source) =>
      source.channels.toSet();

  static String? logoUrlToEntity(final ShopStoreInfoDto source) =>
      PublicImageUrl.ofOrNull(source.logoPath);
}
