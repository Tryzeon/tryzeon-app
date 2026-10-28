import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type_measurements.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_image_analysis.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_form.dart';

import '../../../../../support/product_color_fixtures.dart';

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
  images: ValueNotifier<List<ImageItem>>(const []),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    testWidgets("the form's images come from the product's first colour", (
      final tester,
    ) async {
      late ProductFormData form;
      await tester.pumpWidget(
        HookBuilder(
          builder: (final _) {
            form = useProductForm(
              initialProduct: _archivedProduct.copyWith(
                colors: [
                  productColorFixture(imagePaths: const ['a.jpg', 'b.jpg']),
                  productColorFixture(imagePaths: const ['c.jpg'], position: 1),
                ],
              ),
            );
            return const SizedBox();
          },
        ),
      );

      expect(form.images.value, const [
        ImageItem.existing(path: 'a.jpg', url: 'https://x/a.jpg'),
        ImageItem.existing(path: 'b.jpg', url: 'https://x/b.jpg'),
      ]);
    });

    testWidgets('a product without colours starts with no images', (
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

      expect(form.images.value, isEmpty);
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
