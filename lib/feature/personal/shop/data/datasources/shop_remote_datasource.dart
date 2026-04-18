import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';

class ShopRemoteDataSource {
  ShopRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _productsTable = AppConstants.tableProducts;
  static const _storeProfileTable = AppConstants.tableStoreProfiles;
  static const _logoBucket = AppConstants.bucketStoreLogos;
  static const _productBucket = AppConstants.bucketProductImages;

  Future<List<ShopProductModel>> getProducts({
    final String? storeId,
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final UserLocation? userLocation,
  }) async {
    // 查詢主頁推薦列表所需欄位（詳細資訊由 getProduct 取得）
    dynamic query = _supabaseClient.from(_productsTable).select('''
          id, store_id, name, category_ids, price, image_paths, created_at, updated_at,
          purchase_link, material, elasticity, fit, styles,
          product_variants(*),
          store_profiles!products_store_id_fkey(id, name, address)
        ''');

    // 類型過濾
    if (categories != null && categories.isNotEmpty) {
      query = query.overlaps('category_ids', categories.toList());
    }

    // 店家過濾
    if (storeId != null && storeId.isNotEmpty) {
      query = query.eq('store_id', storeId);
    }

    // 過濾店家名稱或商品名稱
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final condition = StringBuffer();
      condition.write('name.ilike.%$searchQuery%');

      // 找出名稱符合搜尋關鍵字的店家 ID
      final matchingStores = await _supabaseClient
          .from(_storeProfileTable)
          .select('id')
          .ilike('name', '%$searchQuery%');

      final storeIds = (matchingStores as List)
          .map((final e) => e['id'] as String)
          .toList();

      if (storeIds.isNotEmpty) {
        condition.write(',store_id.in.(${storeIds.join(',')})');
      }

      query = query.or(condition.toString());
    }

    // 價格區間過濾
    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
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
      final map = _withProductImageUrl(item);

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

  Future<ShopProductModel> getProduct(final String productId) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .select('''
          *,
          product_variants(*),
          store_profiles!products_store_id_fkey(id, name, address, logo_path)
        ''')
        .eq('id', productId)
        .single();

    final map = _withProductImageUrl(response);
    if (map['store_profiles'] != null) {
      map['store_profiles'] = _withStoreLogoUrl(map['store_profiles']);
    }

    return ShopProductModel.fromJson(map);
  }

  Future<Map<String, dynamic>> getStoreProfile(final String storeId) async {
    final response = await _supabaseClient
        .from(_storeProfileTable)
        .select('id, name, address, logo_path')
        .eq('id', storeId)
        .single();
    return _withStoreLogoUrl(response);
  }

  List<String> _getProductImageUrls(final List<String> imagePaths) {
    return imagePaths
        .map(
          (final path) => _supabaseClient.storage.from(_productBucket).getPublicUrl(path),
        )
        .toList();
  }

  String _getStoreLogoUrl(final String logoPath) {
    return _supabaseClient.storage.from(_logoBucket).getPublicUrl(logoPath);
  }

  Map<String, dynamic> _withProductImageUrl(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    // Fallback to array for mapping correctly
    final rawPaths = map['image_paths'];
    final imagePaths = rawPaths != null ? List<String>.from(rawPaths) : <String>[];

    // We must ensure the field exists for JSON deserialization
    map['image_paths'] = imagePaths;

    if (imagePaths.isNotEmpty) {
      map['image_urls'] = _getProductImageUrls(imagePaths);
    } else {
      map['image_urls'] = <String>[];
    }
    return map;
  }

  Map<String, dynamic> _withStoreLogoUrl(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final logoPath = map['logo_path'] as String?;
    if (logoPath != null && logoPath.isNotEmpty) {
      map['logo_url'] = _getStoreLogoUrl(logoPath);
    }
    return map;
  }
}
