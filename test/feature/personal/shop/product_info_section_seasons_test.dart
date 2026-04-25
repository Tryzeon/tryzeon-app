import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_info_section.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

void main() {
  testWidgets('shows seasons in the personal product info section', (final tester) async {
    final product = ShopProduct(
      storeInfo: const ShopStoreInfo(id: 'store-1', name: 'Season Shop'),
      name: 'Linen Shirt',
      categoryIds: const ['tops'],
      price: 1200,
      imagePaths: const ['path-1'],
      imageUrls: const ['url-1'],
      id: 'product-1',
      seasons: const [ProductSeason.spring, ProductSeason.winter],
      createdAt: DateTime(2026, 4, 25),
      updatedAt: DateTime(2026, 4, 25),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductInfoSection(product: product)),
      ),
    );

    final detailBodySource = File(
      'lib/feature/personal/shop/presentation/widgets/product_detail_body.dart',
    ).readAsStringSync();

    expect(find.text('季節'), findsOneWidget);
    expect(find.text('春、冬'), findsOneWidget);
    expect(
      detailBodySource,
      contains('(product.seasons != null && product.seasons!.isNotEmpty)'),
    );
  });

  testWidgets('shows stored fit strings directly', (final tester) async {
    final presetFitProduct = ShopProduct(
      storeInfo: const ShopStoreInfo(id: 'store-1', name: 'Fit Shop'),
      name: 'Regular Shirt',
      categoryIds: const ['tops'],
      price: 980,
      imagePaths: const ['path-1'],
      imageUrls: const ['url-1'],
      id: 'product-1',
      fit: '常規',
      createdAt: DateTime(2026, 4, 25),
      updatedAt: DateTime(2026, 4, 25),
    );
    final customFitProduct = ShopProduct(
      storeInfo: const ShopStoreInfo(id: 'store-1', name: 'Fit Shop'),
      name: 'Custom Shirt',
      categoryIds: const ['tops'],
      price: 1080,
      imagePaths: const ['path-2'],
      imageUrls: const ['url-2'],
      id: 'product-2',
      fit: 'Boxy',
      createdAt: DateTime(2026, 4, 25),
      updatedAt: DateTime(2026, 4, 25),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ProductInfoSection(product: presetFitProduct),
              ProductInfoSection(product: customFitProduct),
            ],
          ),
        ),
      ),
    );

    final infoSectionSource = File(
      'lib/feature/personal/shop/presentation/widgets/product_info_section.dart',
    ).readAsStringSync();

    expect(find.text('版型'), findsNWidgets(2));
    expect(find.text('常規'), findsOneWidget);
    expect(find.text('Boxy'), findsOneWidget);
    expect(infoSectionSource, isNot(contains('fitDisplayLabel(')));
  });
}
