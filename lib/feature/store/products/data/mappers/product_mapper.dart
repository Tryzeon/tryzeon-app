import 'package:tryzeon/core/shared/measurements/collections/size_measurements_collection.dart';
import '../collections/product_collection.dart';
import '../models/product_model.dart';

extension ProductModelMapper on ProductModel {
  ProductCollection toCollection() {
    return ProductCollection()
      ..productId = id ?? ''
      ..storeId = storeId
      ..name = name
      ..types = types.toList()
      ..price = price
      ..imagePath = imagePath
      ..imageUrl = imageUrl
      ..purchaseLink = purchaseLink
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..storeName = storeName
      ..sizes = sizes?.map((final e) => e.toCollection()).toList();
  }
}

extension ProductCollectionMapper on ProductCollection {
  ProductModel toModel() {
    return ProductModel(
      storeId: storeId,
      name: name,
      types: types?.toSet() ?? {},
      price: price ?? 0.0,
      imagePath: imagePath ?? '',
      imageUrl: imageUrl ?? '',
      id: productId,
      purchaseLink: purchaseLink,
      sizes: sizes?.map((final e) => e.toModel()).toList(),
      storeName: storeName,
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
      ..measurements = (SizeMeasurementsCollection()
        ..height = height
        ..chest = chest
        ..waist = waist
        ..hips = hips
        ..shoulder = shoulder
        ..sleeve = sleeve
        ..heightOffset = heightOffset
        ..chestOffset = chestOffset
        ..waistOffset = waistOffset
        ..hipsOffset = hipsOffset
        ..shoulderOffset = shoulderOffset
        ..sleeveOffset = sleeveOffset)
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension ProductSizeCollectionMapper on ProductSizeCollection {
  ProductSizeModel toModel() {
    return ProductSizeModel(
      id: id,
      productId: productId,
      name: name ?? '',
      height: measurements?.height,
      chest: measurements?.chest,
      waist: measurements?.waist,
      hips: measurements?.hips,
      shoulder: measurements?.shoulder,
      sleeve: measurements?.sleeve,
      heightOffset: measurements?.heightOffset,
      chestOffset: measurements?.chestOffset,
      waistOffset: measurements?.waistOffset,
      hipsOffset: measurements?.hipsOffset,
      shoulderOffset: measurements?.shoulderOffset,
      sleeveOffset: measurements?.sleeveOffset,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
