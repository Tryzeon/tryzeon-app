import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/product_color/data/product_color_order.dart';
import 'package:tryzeon/feature/common/product_color/data/product_color_table.dart';
import 'package:tryzeon/feature/common/product_size/data/product_size_table.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/list_shop_products_request.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_product_dto.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_store_info_dto.dart';

class ShopRemoteDataSource {
  ShopRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _listShopProductsRpc = 'list_shop_products';
  static const _productsTable = 'products';
  static const _storeProfileTable = 'store_profiles';
  static const _productSizesTable = ProductSizeTable.name;
  static const _productColorsTable = ProductColorTable.name;
  static const _productsStoreIdFk = 'products_store_id_fkey';
  static const _storeInfoColumns =
      'id, name, slug, address, logo_path, channels, order_contacts';

  Future<List<ShopProductDto>> listProducts(
    final ListShopProductsRequest request,
  ) async {
    final response = await _supabaseClient.rpc<List<dynamic>>(
      _listShopProductsRpc,
      params: request.toJson(),
    );

    return response
        .map(
          (final item) => ShopProductDto.fromJson(
            Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  Future<ShopProductDto> getProduct(final String productId) async {
    if (!_uuidPattern.hasMatch(productId)) throw const NotFoundException();

    final response = await _supabaseClient
        .from(_productsTable)
        .select('''
          *,
          $_productSizesTable(*),
          $_productColorsTable(*),
          $_storeProfileTable!$_productsStoreIdFk($_storeInfoColumns)
        ''')
        .eq('id', productId)
        .orderProductColors()
        .single();

    return ShopProductDto.fromJson(response);
  }

  /// Both the uuid and the slug form back the same `/store/...` deep link, so
  /// existing uuid links keep working.
  Future<ShopStoreInfoDto> getStoreProfile(final String storeIdOrSlug) async {
    final column = _uuidPattern.hasMatch(storeIdOrSlug) ? 'id' : 'slug';
    final response = await _supabaseClient
        .from(_storeProfileTable)
        .select(_storeInfoColumns)
        .eq(column, storeIdOrSlug)
        .single();
    return ShopStoreInfoDto.fromJson(response);
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
