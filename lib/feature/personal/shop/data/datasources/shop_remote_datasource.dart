import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/list_shop_products_request.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_product_dto.dart';

class ShopRemoteDataSource {
  ShopRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _productsTable = AppConstants.tableProducts;
  static const _storeProfileTable = AppConstants.tableStoreProfiles;

  Future<List<ShopProductDto>> listProducts(
    final ListShopProductsRequest request,
  ) async {
    final response = await _supabaseClient.rpc<List<dynamic>>(
      AppConstants.rpcListShopProducts,
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
          ${AppConstants.tableProductSizes}(*),
          ${AppConstants.tableStoreProfiles}!products_store_id_fkey(id, name, slug, address, logo_path, channels)
        ''')
        .eq('id', productId)
        .single();

    return ShopProductDto.fromJson(response);
  }

  /// Both the uuid and the slug form back the same `/store/...` deep link, so
  /// existing uuid links keep working.
  Future<Map<String, dynamic>> getStoreProfile(
    final String storeIdOrSlug,
  ) async {
    final column = _uuidPattern.hasMatch(storeIdOrSlug) ? 'id' : 'slug';
    final response = await _supabaseClient
        .from(_storeProfileTable)
        .select('id, name, slug, address, logo_path, channels')
        .eq(column, storeIdOrSlug)
        .single();
    return response;
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
