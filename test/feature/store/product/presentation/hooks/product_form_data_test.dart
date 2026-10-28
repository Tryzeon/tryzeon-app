import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type_measurements.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_image_analysis.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_color_manager.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_form.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_colors_editor.dart';
import 'package:typed_result/typed_result.dart';

const _pants = ProductCategory(
  id: 'cat-pants',
  code: 'jeans',
  name: '牛仔褲',
  defaultGarmentType: GarmentType.pants,
);

const _top = ProductCategory(
  id: 'cat-top',
  code: 'tee',
  name: 'T 恤',
  defaultGarmentType: GarmentType.top,
);

ProductFormData _formData() => ProductFormData(
  formKey: GlobalKey<FormState>(),
  nameController: TextEditingController(),
  priceController: TextEditingController(),
  purchaseLinkController: TextEditingController(),
  descriptionController: TextEditingController(),
  selectedGender: ValueNotifier<ProductGender?>(null),
  selectedMaterial: ValueNotifier<String?>(null),
  selectedFit: ValueNotifier<ProductFit?>(null),
  selectedCategoryId: ValueNotifier<String?>(null),
  selectedGarmentType: ValueNotifier<GarmentType?>(null),
  selectedElasticity: ValueNotifier<ProductElasticity?>(null),
  selectedThickness: ValueNotifier<ProductThickness?>(null),
  selectedStyles: ValueNotifier<Set<ClothingStyle>?>(null),
  selectedSeasons: ValueNotifier<Set<ProductSeason>?>(null),
  status: ValueNotifier<ProductStatus>(ProductStatus.active),
);

final _archivedProduct = Product(
  id: 'p1',
  storeId: 's1',
  name: 'Tee',
  categoryId: _top.id,
  garmentType: GarmentType.top,
  price: 500,
  colors: const [],
  status: ProductStatus.archived,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

ImageItem _photo(final String path) => ImageItem.newImage(file: File(path));

Future<ProductColorManager Function()> _pumpForm(
  final WidgetTester tester,
  final ProductFormData data,
) async {
  late ProductColorManager manager;
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HookBuilder(
              builder: (final _) {
                manager = useProductColorManager(
                  analyze: (final _) async => const Ok(
                    ProductImageAnalysis(attributes: ProductAnalysisResult()),
                  ),
                );
                return Form(
                  key: data.formKey,
                  child: Column(
                    children: [
                      ProductColorsEditor(
                        manager: manager,
                        onPickImage: (final _) async => null,
                      ),
                      TextFormField(
                        controller: data.nameController,
                        validator: (final value) =>
                            value!.isEmpty ? '請輸入商品名稱' : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  return () => manager;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('validate', () {
    testWidgets('opening a collapsed colour still flags the rest of the form', (
      final tester,
    ) async {
      final data = _formData();
      final manager = await _pumpForm(tester, data);
      manager().entries.single
        ..images.value = [_photo('a.jpg')]
        ..nameController.text = '黑';
      manager().addColor();
      await tester.pumpAndSettle();
      manager().expand(manager().entries.first);
      await tester.pumpAndSettle();

      expect(data.validate(colors: manager()), isFalse);
      await tester.pumpAndSettle();

      expect(manager().expanded, manager().entries.last);
      expect(find.text('請為這個顏色選擇至少一張照片'), findsOneWidget);
      expect(find.text('請輸入商品名稱'), findsOneWidget);
    });

    testWidgets('a colour issue with no field of its own still blocks saving', (
      final tester,
    ) async {
      final data = _formData()..nameController.text = 'Tee';
      final manager = await _pumpForm(tester, data);
      manager().entries.single.images.value = [
        for (var i = 0; i <= AppConstants.maxProductImages; i++)
          _photo('$i.jpg'),
      ];
      await tester.pumpAndSettle();

      expect(data.validate(colors: manager()), isFalse);
    });
  });

  group('ProductFormData', () {
    test('offers every measurement before a category is chosen', () {
      final form = _formData();

      expect(form.selectedCategoryId.value, isNull);
      expect(form.selectedGarmentType.value, isNull);
      expect(form.visibleMeasurementTypes, GarmentMeasurementType.values);
    });

    test('selectCategory sets the category and its garment type together', () {
      final form = _formData();

      form.selectCategory(_pants);

      expect(form.selectedCategoryId.value, _pants.id);
      expect(form.selectedGarmentType.value, GarmentType.pants);
      expect(form.visibleMeasurementTypes, GarmentType.pants.measurementTypes);
    });

    test('applyAnalysis selects the analyzed category', () {
      final form = _formData();

      form.applyAnalysis(
        const ProductImageAnalysis(
          attributes: ProductAnalysisResult(categoryId: 'cat-top'),
          category: _top,
        ),
      );

      expect(form.selectedCategoryId.value, _top.id);
      expect(form.selectedGarmentType.value, GarmentType.top);
    });

    test('applyAnalysis leaves both unset without a category', () {
      final form = _formData();

      form.applyAnalysis(
        const ProductImageAnalysis(
          attributes: ProductAnalysisResult(categoryId: 'cat-unknown'),
        ),
      );

      expect(form.selectedCategoryId.value, isNull);
      expect(form.selectedGarmentType.value, isNull);
    });

    test('applyAnalysis does not override a category already chosen', () {
      final form = _formData()..selectCategory(_pants);

      form.applyAnalysis(
        const ProductImageAnalysis(
          attributes: ProductAnalysisResult(categoryId: 'cat-top'),
          category: _top,
        ),
      );

      expect(form.selectedCategoryId.value, _pants.id);
      expect(form.selectedGarmentType.value, GarmentType.pants);
    });

    test('toDraft carries the publish switch', () {
      final form = _formData()
        ..nameController.text = 'Tee'
        ..priceController.text = '500'
        ..selectCategory(_top);
      form.selectedGender.value = ProductGender.unisex;

      form.status.value = ProductStatus.archived;

      expect(form.toDraft().status, ProductStatus.archived);
    });

    testWidgets("the form starts from the product's status", (
      final tester,
    ) async {
      late ProductFormData form;
      await tester.pumpWidget(
        HookBuilder(
          builder: (final _) {
            form = useProductForm(initialProduct: _archivedProduct);
            return const SizedBox();
          },
        ),
      );

      expect(form.status.value, ProductStatus.archived);
    });

    testWidgets('a new product defaults to published', (final tester) async {
      late ProductFormData form;
      await tester.pumpWidget(
        HookBuilder(
          builder: (final _) {
            form = useProductForm();
            return const SizedBox();
          },
        ),
      );

      expect(form.status.value, ProductStatus.active);
    });
  });
}
