import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/garment_type/data/mappers/garment_type_cache_converters.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_cache.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/create_wardrobe_item_request.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/label_result_dto.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/update_wardrobe_item_request.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/wardrobe_item_dto.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/mappers/wardrobe_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/label_result.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/new_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item_update.dart';

@AutoMappr([
  MapType<WardrobeItemDto, WardrobeItem>(),
  MapType<LabelResultDto, LabelResult>(),
  MapType<NewWardrobeItem, CreateWardrobeItemRequest>(),
  MapType<WardrobeItemUpdate, UpdateWardrobeItemRequest>(),
  MapType<WardrobeItem, WardrobeItemCache>(
    fields: [Field('itemId', from: 'id')],
    converters: [
      TypeConverter<GarmentType, String>(GarmentTypeCacheConverters.toCache),
    ],
  ),
  MapType<WardrobeItemCache, WardrobeItem>(
    fields: [Field('id', from: 'itemId')],
    converters: [
      TypeConverter<String, GarmentType>(GarmentTypeCacheConverters.fromCache),
    ],
  ),
])
class WardrobeMappr extends $WardrobeMappr {
  const WardrobeMappr();
}
