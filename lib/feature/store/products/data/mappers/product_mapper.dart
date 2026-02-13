import 'package:tryzeon/core/shared/measurements/data/models/size_measurements_model.dart';

import '../collections/product_collection.dart';
import '../models/product_model.dart';

extension ProductModelMapper on ProductModel {
  ProductCollection toCollection() {
    return ProductCollection()
      ..productId = id
      ..storeId = storeId
      ..name = name
      ..categories = categories.toList()
      ..price = price
      ..imagePath = imagePath
      ..imageUrl = imageUrl
      ..purchaseLink = purchaseLink
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..sizes = sizes?.map((final e) => e.toCollection()).toList();
  }
}

extension ProductCollectionMapper on ProductCollection {
  ProductModel toModel() {
    return ProductModel(
      storeId: storeId,
      name: name,
      categories: categories.toSet(),
      price: price,
      imagePath: imagePath,
      imageUrl: imageUrl,
      id: productId,
      purchaseLink: purchaseLink,
      sizes: sizes?.map((final e) => e.toModel()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension ProductSizeModelMapper on ProductSizeModel {
  ProductSizeCollection toCollection() {
    return ProductSizeCollection()
      ..id = id
      ..productId = productId
      ..name = name
      ..measurements = measurements?.toCollection()
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension ProductSizeCollectionMapper on ProductSizeCollection {
  ProductSizeModel toModel() {
    return ProductSizeModel(
      id: id,
      productId: productId,
      name: name,
      measurements: measurements != null
          ? SizeMeasurementsModel.fromCollection(measurements!)
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
