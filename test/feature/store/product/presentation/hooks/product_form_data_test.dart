import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type_measurements.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_form.dart';

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

const _categories = [_pants, _top];

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

    test('applyAnalysis selects a known category', () {
      final form = _formData();

      form.applyAnalysis(const ProductAnalysisResult(categoryId: 'cat-top'), _categories);

      expect(form.selectedCategoryId.value, _top.id);
      expect(form.selectedGarmentType.value, GarmentType.top);
    });

    test('applyAnalysis leaves both unset for an unknown category', () {
      final form = _formData();

      form.applyAnalysis(
        const ProductAnalysisResult(categoryId: 'cat-unknown'),
        _categories,
      );

      expect(form.selectedCategoryId.value, isNull);
      expect(form.selectedGarmentType.value, isNull);
    });

    test('applyAnalysis does not override a category already chosen', () {
      final form = _formData()..selectCategory(_pants);

      form.applyAnalysis(const ProductAnalysisResult(categoryId: 'cat-top'), _categories);

      expect(form.selectedCategoryId.value, _pants.id);
      expect(form.selectedGarmentType.value, GarmentType.pants);
    });
  });
}
