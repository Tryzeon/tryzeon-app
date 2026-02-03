import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/common/product_categories/data/models/product_category_model.dart';

class ProductCategoryRemoteDataSource {
  ProductCategoryRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _productCategoryTable = AppConstants.tableProductCategories;

  Future<List<ProductCategoryModel>> getProductCategories() async {
    final response = await _supabaseClient
        .from(_productCategoryTable)
        .select('id, name')
        .order('priority', ascending: false);

    return (response as List)
        .map((final e) => ProductCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
