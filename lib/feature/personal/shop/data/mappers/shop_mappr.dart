import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:collection/collection.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/product_size_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/product_size_mappr.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/standard_size_label.dart';
import 'package:tryzeon/feature/common/store/data/dtos/store_order_contact_dto.dart';
import 'package:tryzeon/feature/common/store/data/mappers/order_contacts_converters.dart';
import 'package:tryzeon/feature/common/store/domain/entities/order_contact_type.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_product_dto.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_store_info_dto.dart';
import 'package:tryzeon/feature/personal/shop/data/mappers/shop_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';

@AutoMappr(
  [
    MapType<ShopProductDto, ShopProduct>(
      fields: [
        Field('imageUrls', custom: ShopMapprHelper.imageUrlsToEntity),
        Field('sizes', custom: ShopMapprHelper.sizesToEntity),
        Field('styles', custom: ShopMapprHelper.stylesToEntity),
        Field('seasons', custom: ShopMapprHelper.seasonsToEntity),
      ],
    ),
    MapType<ShopStoreInfoDto, ShopStoreInfo>(
      fields: [Field('logoUrl', custom: ShopMapprHelper.logoUrlToEntity)],
      converters: [
        TypeConverter<
          List<StoreOrderContactDto>,
          Map<OrderContactType, String>
        >(OrderContactsConverters.fromDtos),
      ],
    ),
  ],
  includes: [ProductSizeMappr()],
)
class ShopMappr extends $ShopMappr {
  const ShopMappr();
}

class ShopMapprHelper {
  static List<String> imageUrlsToEntity(final ShopProductDto source) =>
      source.imagePaths.map(PublicImageUrl.of).toList();

  /// Embedded `product_sizes` rows come back in no guaranteed order.
  static List<ProductSize>? sizesToEntity(final ShopProductDto source) {
    final dtos = source.sizes;
    if (dtos == null) return null;
    final sizes = const ProductSizeMappr()
        .convertList<ProductSizeDto, ProductSize>(dtos);
    mergeSort(
      sizes,
      compare: (final a, final b) => compareSizeLabels(a.name, b.name),
    );
    return sizes;
  }

  static Set<ClothingStyle>? stylesToEntity(final ShopProductDto source) =>
      source.styles?.toSet();

  static Set<ProductSeason>? seasonsToEntity(final ShopProductDto source) =>
      source.seasons?.toSet();

  static String? logoUrlToEntity(final ShopStoreInfoDto source) =>
      PublicImageUrl.ofOrNull(source.logoPath);
}
