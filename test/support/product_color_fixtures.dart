import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';

ProductColor productColorFixture({
  final List<String> imagePaths = const [],
  final List<String>? imageUrls,
  final int position = 0,
  final String productId = 'p1',
}) => ProductColor(
  id: 'color-$productId-$position',
  productId: productId,
  imagePaths: imagePaths,
  imageUrls: imageUrls ?? [for (final path in imagePaths) 'https://x/$path'],
  position: position,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
