import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/domain/entities/user_location.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/product_sort_option.dart';

class ShopRemoteDataSource {
  ShopRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _productsTable = AppConstants.tableProducts;
  static const _storeProfileTable = AppConstants.tableStoreProfile;
  static const _storeBucket = AppConstants.bucketStore;

  Future<List<ShopProductModel>> getProducts({
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final UserLocation? userLocation,
  }) async {
    // 查詢所有商品並關聯店家資訊和尺寸資訊
    dynamic query = _supabaseClient.from(_productsTable).select('''
          *,
          product_sizes(*),
          store_profile!inner(*)
        ''');

    // 搜尋過濾
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // 1. 先找出名稱符合搜尋關鍵字的店家 ID
      final matchingStores = await _supabaseClient
          .from(_storeProfileTable)
          .select('id')
          .ilike('name', '%$searchQuery%');

      final storeIds = (matchingStores as List)
          .map((final e) => e['id'] as String)
          .toList();

      // 2. 構建 OR 查詢條件
      final buffer = StringBuffer();
      buffer.write('name.ilike.%$searchQuery%');
      buffer.write(',type.cs.{$searchQuery}');

      if (storeIds.isNotEmpty) {
        buffer.write(',store_id.in.(${storeIds.join(',')})');
      }

      query = query.or(buffer.toString());
    }

    // 價格區間過濾
    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }
    // 類型過濾（使用 PostgreSQL 陣列 overlap 操作符）
    if (types != null && types.isNotEmpty) {
      query = query.overlaps('type', types.toList());
    }

    // 排序邏輯
    final String dbSortColumn;
    final bool isAscending;

    switch (sortOption) {
      case ProductSortOption.priceLowToHigh:
        dbSortColumn = 'price';
        isAscending = true;
      case ProductSortOption.priceHighToLow:
        dbSortColumn = 'price';
        isAscending = false;
      case ProductSortOption.latest:
        dbSortColumn = 'created_at';
        isAscending = false;
    }

    // 排序
    final response = await query.order(dbSortColumn, ascending: isAscending);

    // 將結果轉換為 Model
    var products = (response as List).map((final item) {
      final map = Map<String, dynamic>.from(item);
      final imagePath = map['image_path'] as String?;
      if (imagePath != null) {
        map['image_url'] = getProductImageUrl(imagePath);
      }

      // 處理店家 Logo
      if (map['store_profile'] != null) {
        final storeProfile = Map<String, dynamic>.from(map['store_profile']);
        final logoPath = storeProfile['logo_path'] as String?;
        if (logoPath != null && logoPath.isNotEmpty) {
          storeProfile['logo_url'] = getProductImageUrl(logoPath);
        }
        map['store_profile'] = storeProfile;
      }

      return ShopProductModel.fromJson(map);
    }).toList();

    // 若有使用者位置，依接近度排序：同區優先 > 同城市 > 其他
    if (userLocation != null) {
      final sameDistrict = <ShopProductModel>[];
      final sameCity = <ShopProductModel>[];
      final otherCity = <ShopProductModel>[];

      for (final product in products) {
        if (userLocation.isSameDistrict(product.storeInfo.address)) {
          sameDistrict.add(product);
        } else if (userLocation.isSameCity(product.storeInfo.address)) {
          sameCity.add(product);
        } else {
          otherCity.add(product);
        }
      }

      products = [...sameDistrict, ...sameCity, ...otherCity];
    }

    return products;
  }

  String getProductImageUrl(final String imagePath) {
    return _supabaseClient.storage.from(_storeBucket).getPublicUrl(imagePath);
  }

  Future<void> incrementTryonCount(final String productId) async {
    await _supabaseClient.rpc(
      'increment_tryon_count',
      params: {'product_uuid': productId},
    );
  }

  Future<void> incrementPurchaseClickCount(final String productId) async {
    await _supabaseClient.rpc(
      'increment_purchase_click_count',
      params: {'product_uuid': productId},
    );
  }
}
