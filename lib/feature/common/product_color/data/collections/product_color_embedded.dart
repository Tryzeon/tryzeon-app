import 'package:isar_community/isar.dart';

part 'product_color_embedded.g.dart';

@embedded
class ProductColorEmbedded {
  late String id;
  late String productId;
  String? name;
  late List<String> imagePaths;
  late int position;
  late DateTime createdAt;
  late DateTime updatedAt;
}
