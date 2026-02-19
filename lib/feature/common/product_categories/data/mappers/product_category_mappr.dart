import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/product_category.dart';
import '../collections/product_category_collection.dart';
import '../models/product_category_model.dart';
import 'product_category_mappr.auto_mappr.dart';

/// AutoMappr configuration for ProductCategory (Common module)
@AutoMappr([
  MapType<ProductCategoryModel, ProductCategory>(),
  MapType<ProductCategory, ProductCategoryModel>(),
  MapType<ProductCategoryModel, ProductCategoryCollection>(
    fields: [Field('categoryId', from: 'id')],
  ),
  MapType<ProductCategoryCollection, ProductCategoryModel>(
    fields: [Field('id', from: 'categoryId')],
  ),
])
class ProductCategoryMappr extends $ProductCategoryMappr {
  const ProductCategoryMappr();
}
