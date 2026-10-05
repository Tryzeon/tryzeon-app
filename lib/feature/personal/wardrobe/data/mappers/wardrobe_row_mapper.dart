import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/wardrobe_item_dto.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

const _mappr = PersonalMappr();

WardrobeItem decodeWardrobeItemRow(final Map<String, dynamic> row) => _mappr
    .convert<WardrobeItemDto, WardrobeItem>(WardrobeItemDto.fromJson(row));
