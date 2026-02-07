import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_store_info.freezed.dart';

@freezed
sealed class ShopStoreInfo with _$ShopStoreInfo {
  const factory ShopStoreInfo({
    required final String id,
    required final String name,
    final String? address,
    final String? logoUrl,
  }) = _ShopStoreInfo;
}
