import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_form.dart';

void main() {
  test('includes seasons in form conversions and UI wiring', () {
    final seasons = [ProductSeason.spring, ProductSeason.winter];
    final formData = ProductFormData(
      formKey: GlobalKey<FormState>(),
      nameController: TextEditingController(text: 'Linen Shirt'),
      priceController: TextEditingController(text: '1200'),
      purchaseLinkController: TextEditingController(text: ''),
      materialController: TextEditingController(text: ''),
      images: ValueNotifier(const []),
      selectedCategoryIds: ValueNotifier({'tops'}),
      selectedElasticity: ValueNotifier(null),
      selectedFit: ValueNotifier(null),
      selectedThickness: ValueNotifier(null),
      selectedStyles: ValueNotifier(null),
      selectedSeasons: ValueNotifier(seasons),
    );

    final createParams = formData.toCreateProductParams(storeId: 'store-1', sizes: null);
    final product = formData.toProduct(
      id: 'product-1',
      storeId: 'store-1',
      imagePaths: const ['path-1'],
      imageUrls: const ['url-1'],
      sizes: null,
      createdAt: DateTime(2026, 4, 25),
      updatedAt: DateTime(2026, 4, 25),
    );

    final editorSource = File(
      'lib/feature/store/products/presentation/widgets/product_basic_info_editor.dart',
    ).readAsStringSync();
    final layoutSource = File(
      'lib/feature/store/products/presentation/widgets/product_form_layout.dart',
    ).readAsStringSync();
    final detailSource = File(
      'lib/feature/store/products/presentation/pages/product_detail_page.dart',
    ).readAsStringSync();

    expect(createParams.seasons, seasons);
    expect(product.seasons, seasons);
    expect(editorSource, contains('ProductSeasonSelector('));
    expect(editorSource, contains("Text('季節 (選填)'"));
    expect(layoutSource, contains('selectedSeasons: formData.selectedSeasons,'));
    expect(detailSource, contains('seasons: formData.selectedSeasons.value,'));
  });
}
