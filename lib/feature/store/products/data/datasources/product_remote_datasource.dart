import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/store/products/data/mappers/product_sort_field_mapper.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_request.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_size_request.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _productsTable = AppConstants.tableProducts;
  static const _productSizesTable = AppConstants.tableProductVariants;
  static const _productImagesBucket = AppConstants.bucketProductImages;

  Future<List<ProductModel>> getProducts({
    required final String storeId,
    required final SortCondition sort,
  }) async {
    final dbColumn = sort.field.toDbColumn();

    final response = await _supabaseClient
        .from(_productsTable)
        .select('*, product_variants(*)')
        .eq('store_id', storeId)
        .order(dbColumn, ascending: sort.ascending);

    return (response as List).map((final e) {
      return ProductModel.fromJson(_withProductImageUrl(e));
    }).toList();
  }

  Future<String> insertProduct(final CreateProductRequest request) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .insert(request.toJson())
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> insertProductSizes(final List<CreateProductSizeRequest> requests) async {
    final sizesData = requests.map((final e) => e.toJson()).toList();
    await _supabaseClient.from(_productSizesTable).insert(sizesData);
  }

  Future<ProductModel> getProduct(final String productId) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .select('*, product_variants(*)')
        .eq('id', productId)
        .single();

    return ProductModel.fromJson(_withProductImageUrl(response));
  }

  Future<void> updateProduct(final ProductModel product) async {
    final json = product.toJson()
      ..remove('id')
      ..remove('store_id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('product_variants');

    await _supabaseClient.from(_productsTable).update(json).eq('id', product.id);
  }

  Future<void> deleteProduct(final String productId) async {
    await _supabaseClient.from(_productsTable).delete().eq('id', productId);
  }

  Future<void> deleteProductSizes(final String productId) async {
    await _supabaseClient.from(_productSizesTable).delete().eq('product_id', productId);
  }

  Future<void> deleteProductSize(final String sizeId) async {
    await _supabaseClient.from(_productSizesTable).delete().eq('id', sizeId);
  }

  Future<void> insertProductSize(final CreateProductSizeRequest request) async {
    await _supabaseClient.from(_productSizesTable).insert(request.toJson());
  }

  Future<void> updateProductSize(final ProductSizeModel size) async {
    final json = size.toJson()
      ..remove('id')
      ..remove('product_id')
      ..remove('created_at')
      ..remove('updated_at');

    await _supabaseClient.from(_productSizesTable).update(json).eq('id', size.id);
  }

  Future<String> uploadProductImage({
    required final String storeId,
    required final File image,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final imageName = p.basename(image.path);
    final productImagePath = '$storeId/products/$imageName';
    final mimeType = lookupMimeType(image.path);

    final bytes = await image.readAsBytes();
    await _supabaseClient.storage
        .from(_productImagesBucket)
        .uploadBinary(
          productImagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

    return productImagePath;
  }

  Future<void> deleteProductImage(final String imagePath) async {
    if (imagePath.isEmpty) return;
    await _supabaseClient.storage.from(_productImagesBucket).remove([imagePath]);
  }

  String getProductImageUrl(final String imagePath) {
    if (imagePath.isEmpty) return '';
    return _supabaseClient.storage.from(_productImagesBucket).getPublicUrl(imagePath);
  }

  Map<String, dynamic> _withProductImageUrl(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final imagePath = map['image_path'] as String?;
    if (imagePath != null && imagePath.isNotEmpty) {
      map['image_url'] = getProductImageUrl(imagePath);
    }
    return map;
  }
}
