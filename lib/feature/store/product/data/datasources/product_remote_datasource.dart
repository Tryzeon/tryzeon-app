import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/common/product_color/data/product_color_order.dart';
import 'package:tryzeon/feature/common/product_color/data/product_color_table.dart';
import 'package:tryzeon/feature/common/product_size/data/product_size_table.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_color_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_size_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_dto.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _productsTable = 'products';
  static const _productSizesTable = ProductSizeTable.name;
  static const _productColorsTable = ProductColorTable.name;
  static const _productSelect =
      '*, $_productSizesTable(*), $_productColorsTable(*)';

  Future<List<ProductDto>> listProducts({required final String storeId}) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .select(_productSelect)
        .eq('store_id', storeId)
        .orderProductColors();

    return (response as List<dynamic>)
        .map((final e) => ProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertProduct(final CreateProductRequest request) async {
    await _supabaseClient.from(_productsTable).insert(request.toJson());
  }

  Future<void> insertProductColors(
    final List<CreateProductColorRequest> requests,
  ) async {
    await _supabaseClient.from(_productColorsTable).insert([
      for (final request in requests) request.toJson(),
    ]);
  }

  Future<void> insertProductSizes(
    final List<CreateProductSizeRequest> requests,
  ) async {
    await _supabaseClient.from(_productSizesTable).insert([
      for (final request in requests) request.toJson(),
    ]);
  }

  Future<ProductDto> getProduct(final String productId) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .select(_productSelect)
        .eq('id', productId)
        .orderProductColors()
        .single();

    return ProductDto.fromJson(response);
  }

  Future<void> updateProduct(
    final String productId,
    final Map<String, dynamic> changes,
  ) async {
    await _supabaseClient
        .from(_productsTable)
        .update(changes)
        .eq('id', productId)
        .select('id')
        .single();
  }

  Future<void> updateProductColor(
    final String colorId,
    final Map<String, dynamic> changes,
  ) async {
    await _supabaseClient
        .from(_productColorsTable)
        .update(changes)
        .eq('id', colorId)
        .select('id')
        .single();
  }

  Future<void> deleteProductColor(final String colorId) async {
    await _supabaseClient.from(_productColorsTable).delete().eq('id', colorId);
  }

  Future<void> deleteProduct(final String productId) async {
    await _supabaseClient.from(_productsTable).delete().eq('id', productId);
  }

  Future<void> deleteProductSize(final String sizeId) async {
    await _supabaseClient.from(_productSizesTable).delete().eq('id', sizeId);
  }

  Future<void> insertProductSize(final CreateProductSizeRequest request) async {
    await _supabaseClient.from(_productSizesTable).insert(request.toJson());
  }

  Future<void> updateProductSize(
    final String sizeId,
    final Map<String, dynamic> changes,
  ) async {
    await _supabaseClient
        .from(_productSizesTable)
        .update(changes)
        .eq('id', sizeId)
        .select('id')
        .single();
  }
}
