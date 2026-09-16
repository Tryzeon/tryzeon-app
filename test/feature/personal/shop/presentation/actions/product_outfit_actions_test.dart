import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/product_fit_resolver.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/product_outfit_actions.dart';
import 'package:tryzeon/feature/personal/shop/providers/product_fit_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/actions/outfit_actions.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/outfit_tray_controller.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

void main() {
  testWidgets(
    'a product piece carries its store, image and resolved size into the tray',
    (final tester) async {
      final product = ShopProduct(
        storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
        name: 'Tee',
        categoryId: 'c',
        garmentType: GarmentType.top,
        price: 690,
        imagePaths: const ['p.jpg'],
        imageUrls: const ['https://x/p.jpg'],
        id: 'p1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      late WidgetRef capturedRef;
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          wardrobeItemsProvider.overrideWith(() => FakeWardrobeItems(const [])),
          productFitResolverProvider.overrideWithValue(
            const ProductFitResolver(body: null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (final _, final ref, final _) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );

      toggleOutfitPiece(capturedRef, outfitPieceFromProduct(capturedRef, product));

      final state = container.read(outfitTrayProvider);
      expect(state.isOpen, isTrue);
      final piece = state.pieces.single as OutfitPieceProduct;
      expect(piece.productId, 'p1');
      expect(piece.imageUrl, 'https://x/p.jpg');
      expect(
        piece.sizeId,
        const ProductFitResolver(body: null).resolve(product).tryonSizeId,
      );

      toggleOutfitPiece(capturedRef, outfitPieceFromProduct(capturedRef, product));
      expect(container.read(outfitTrayProvider).pieces, isEmpty);
    },
  );
}
