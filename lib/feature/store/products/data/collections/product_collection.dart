import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/shared/measurements/collections/measurements_collection.dart';

part 'product_collection.g.dart';

@collection
class ProductCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String productId;

  @Index()
  late String storeId;
  late String name;
  late String categoryId;
  late double price;
  late String imagePath;
  late String imageUrl;
  String? purchaseLink;
  String? material;

  String? elasticity;
  String? fit;

  List<String>? styles;

  DateTime? createdAt;
  DateTime? updatedAt;

  List<ProductSizeCollection>? sizes;
}

@embedded
class ProductSizeCollection {
  late String id;
  late String productId;
  late String name;

  MeasurementsCollection? measurements;
  DateTime? createdAt;
  DateTime? updatedAt;
}
