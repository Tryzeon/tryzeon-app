import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/providers/product_fit_provider.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

OutfitPiece outfitPieceFromProduct(final WidgetRef ref, final ShopProduct product) {
  return OutfitPiece.product(
    productId: product.id,
    name: product.name,
    imageUrl: product.imageUrls.firstOrNull ?? '',
    garmentType: product.garmentType,
    sizeId: ref.read(productFitResolverProvider).resolve(product).tryonSizeId,
  );
}

void triggerProductTryon(
  final BuildContext context,
  final WidgetRef ref,
  final ShopProduct product,
) => triggerOutfitTryon(context, ref, [outfitPieceFromProduct(ref, product)]);
