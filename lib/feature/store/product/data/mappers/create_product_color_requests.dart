import 'package:tryzeon/feature/store/product/data/dtos/create_product_color_request.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';

List<CreateProductColorRequest> toCreateProductColorRequests({
  required final String productId,
  required final String storeId,
  required final List<NewProductColor> colors,
}) => [
  for (final color in colors)
    CreateProductColorRequest(
      productId: productId,
      storeId: storeId,
      name: color.name,
      imagePaths: color.imagePaths,
      position: color.position,
    ),
];
