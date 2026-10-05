import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/config/env.dart';
import 'package:tryzeon/feature/common/product_category/data/dtos/product_category_dto.dart';

class ProductCategoryRemoteDataSource {
  ProductCategoryRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _productCategoryTable = AppConstants.tableProductCategories;

  Future<List<ProductCategoryDto>> getProductCategories() async {
    final response = await _supabaseClient
        .from(_productCategoryTable)
        .select(
          'id, code, name, gender, default_garment_type, image_male, image_female',
        )
        .order('order', ascending: true);

    return (response as List<dynamic>)
        .map(
          (final e) => ProductCategoryDto.fromJson(
            _withCategoryImageUrls(e as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  Map<String, dynamic> _withCategoryImageUrls(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final male = map['image_male'] as String?;
    final female = map['image_female'] as String?;
    if (male != null && male.isNotEmpty) {
      map['image_male_url'] = '${Env.r2PublicImagesBaseUrl}/$male';
    }
    if (female != null && female.isNotEmpty) {
      map['image_female_url'] = '${Env.r2PublicImagesBaseUrl}/$female';
    }
    return map;
  }
}
