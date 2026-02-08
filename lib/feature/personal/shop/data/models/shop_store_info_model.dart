import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';

part 'shop_store_info_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopStoreInfoModel {
  const ShopStoreInfoModel({
    required this.id,
    required this.name,
    this.address,
    this.logoUrl,
  });

  factory ShopStoreInfoModel.fromJson(final Map<String, dynamic> json) =>
      _$ShopStoreInfoModelFromJson(json);

  final String id;
  final String name;
  final String? address;
  final String? logoUrl;

  Map<String, dynamic> toJson() => _$ShopStoreInfoModelToJson(this);

  ShopStoreInfo toEntity() {
    return ShopStoreInfo(id: id, name: name, address: address, logoUrl: logoUrl);
  }
}
