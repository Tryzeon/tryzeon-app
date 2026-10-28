import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_color.freezed.dart';

@freezed
sealed class ProductColor with _$ProductColor {
  const factory ProductColor({
    required final String id,
    required final String productId,
    final String? name,
    required final List<String> imagePaths,
    required final List<String> imageUrls,
    required final int position,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _ProductColor;
}

extension ProductColorsCover on List<ProductColor> {
  ProductColor? get cover => firstOrNull;

  String? get coverImageUrl => cover?.imageUrls.firstOrNull;

  String? get coverImagePath => cover?.imagePaths.firstOrNull;
}
