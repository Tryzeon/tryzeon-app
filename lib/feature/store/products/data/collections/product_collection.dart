import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/shared/measurements/collections/size_measurements_collection.dart';

part 'product_collection.g.dart';

@collection
class ProductCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String productId;

  late String storeId;
  late String name;
  late List<String> categories;
  late double price;
  late String imagePath;
  late String imageUrl;
  String? purchaseLink;
  DateTime? createdAt;
  DateTime? updatedAt;

  List<ProductSizeCollection>? sizes;
}

@embedded
class ProductSizeCollection {
  late String id;
  late String productId;
  late String name;

  SizeMeasurementsCollection? measurements;
  DateTime? createdAt;
  DateTime? updatedAt;
}
