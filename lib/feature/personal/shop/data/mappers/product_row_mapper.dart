import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_product_dto.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';

const _mappr = PersonalMappr();

ShopProduct decodeShopProductRow(final Map<String, dynamic> row) =>
    _mappr.convert<ShopProductDto, ShopProduct>(ShopProductDto.fromJson(row));
