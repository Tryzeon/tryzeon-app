import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:tryzeon/feature/store/products/presentation/extensions/product_attributes_extension.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_form.dart';

void main() {
  test('includes seasons in form conversions and UI wiring', () {
    final seasons = [ProductSeason.spring, ProductSeason.winter];
    final formData = ProductFormData(
      formKey: GlobalKey<FormState>(),
      nameController: TextEditingController(text: 'Linen Shirt'),
      priceController: TextEditingController(text: '1200'),
      purchaseLinkController: TextEditingController(text: ''),
      materialOtherController: TextEditingController(text: ''),
      selectedMaterialPreset: ValueNotifier(null),
      fitOtherController: TextEditingController(text: ''),
      selectedFitPreset: ValueNotifier(null),
      images: ValueNotifier(const []),
      selectedCategoryIds: ValueNotifier({'tops'}),
      selectedElasticity: ValueNotifier(null),
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
    expect(editorSource, isNot(contains('const SizedBox(width: 16),')));
    expect(layoutSource, contains('selectedSeasons: formData.selectedSeasons,'));
    expect(detailSource, contains('seasons: formData.selectedSeasons.value,'));
  });

  test('uses preset material and fit values directly in form conversions', () {
    final formData = ProductFormData(
      formKey: GlobalKey<FormState>(),
      nameController: TextEditingController(text: 'Cotton Tee'),
      priceController: TextEditingController(text: '980'),
      purchaseLinkController: TextEditingController(text: ''),
      materialOtherController: TextEditingController(text: ''),
      selectedMaterialPreset: ValueNotifier('棉'),
      fitOtherController: TextEditingController(text: ''),
      selectedFitPreset: ValueNotifier('常規'),
      images: ValueNotifier(const []),
      selectedCategoryIds: ValueNotifier({'tops'}),
      selectedElasticity: ValueNotifier(null),
      selectedThickness: ValueNotifier(null),
      selectedStyles: ValueNotifier(null),
      selectedSeasons: ValueNotifier(const [ProductSeason.spring]),
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

    expect(createParams.material, '棉');
    expect(createParams.fit, '常規');
    expect(product.material, '棉');
    expect(product.fit, '常規');
  });

  test('uses custom material and fit text when the other sentinel is selected', () {
    final formData = ProductFormData(
      formKey: GlobalKey<FormState>(),
      nameController: TextEditingController(text: 'Custom Jacket'),
      priceController: TextEditingController(text: '1680'),
      purchaseLinkController: TextEditingController(text: ''),
      materialOtherController: TextEditingController(text: '再生纖維'),
      selectedMaterialPreset: ValueNotifier(kOtherSentinel),
      fitOtherController: TextEditingController(text: 'Boxy'),
      selectedFitPreset: ValueNotifier(kOtherSentinel),
      images: ValueNotifier(const []),
      selectedCategoryIds: ValueNotifier({'outer'}),
      selectedElasticity: ValueNotifier(null),
      selectedThickness: ValueNotifier(null),
      selectedStyles: ValueNotifier(null),
      selectedSeasons: ValueNotifier(const [ProductSeason.winter]),
    );

    final createParams = formData.toCreateProductParams(storeId: 'store-1', sizes: null);
    final product = formData.toProduct(
      id: 'product-2',
      storeId: 'store-1',
      imagePaths: const ['path-2'],
      imageUrls: const ['url-2'],
      sizes: null,
      createdAt: DateTime(2026, 4, 25),
      updatedAt: DateTime(2026, 4, 25),
    );

    expect(createParams.material, '再生纖維');
    expect(createParams.fit, 'Boxy');
    expect(product.material, '再生纖維');
    expect(product.fit, 'Boxy');
  });

  testWidgets('recognizes stored Chinese preset fit values when editing', (
    final tester,
  ) async {
    late ProductFormData formData;

    final initialProduct = Product(
      storeId: 'store-1',
      name: 'Preset Fit Tee',
      categoryIds: const ['tops'],
      price: 980,
      imagePaths: const [],
      imageUrls: const [],
      id: 'product-1',
      fit: '常規',
      createdAt: DateTime(2026, 4, 25),
      updatedAt: DateTime(2026, 4, 25),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HookBuilder(
          builder: (final context) {
            formData = useProductForm(initialProduct: initialProduct);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(formData.selectedFitPreset.value, '常規');
    expect(formData.fitOtherController.text, isEmpty);
  });
}
