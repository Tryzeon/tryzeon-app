import 'package:tryzeon/feature/store/product/data/dtos/create_product_color_request.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';

List<CreateProductColorRequest> toCreateProductColorRequests(
  final NewProduct product,
) => [
  for (final (index, color) in product.colors.indexed)
    CreateProductColorRequest(
      productId: product.id,
      storeId: product.storeId,
      name: color.name,
      imagePaths: color.imagePaths,
      position: index,
    ),
];
