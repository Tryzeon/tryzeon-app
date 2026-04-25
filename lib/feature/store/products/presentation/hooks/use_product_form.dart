import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:tryzeon/feature/store/products/presentation/extensions/product_attributes_extension.dart';

class ProductFormData {
  ProductFormData({
    required this.formKey,
    required this.nameController,
    required this.priceController,
    required this.purchaseLinkController,
    required this.selectedMaterialPreset,
    required this.materialOtherController,
    required this.selectedFitPreset,
    required this.fitOtherController,
    required this.images,
    required this.selectedCategoryIds,
    required this.selectedElasticity,
    required this.selectedThickness,
    required this.selectedStyles,
    required this.selectedSeasons,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchaseLinkController;
  final ValueNotifier<String?> selectedMaterialPreset;
  final TextEditingController materialOtherController;
  final ValueNotifier<String?> selectedFitPreset;
  final TextEditingController fitOtherController;
  final ValueNotifier<List<ImageItem>> images;
  final ValueNotifier<Set<String>> selectedCategoryIds;
  final ValueNotifier<ProductElasticity?> selectedElasticity;
  final ValueNotifier<ProductThickness?> selectedThickness;
  final ValueNotifier<List<ClothingStyle>?> selectedStyles;
  final ValueNotifier<List<ProductSeason>?> selectedSeasons;

  bool validate(final BuildContext context) {
    return formKey.currentState?.validate() ?? false;
  }

  /// Extract only new images (files pending upload)
  List<File> get newImageFiles =>
      images.value.whereType<NewImageItem>().map((final e) => e.file).toList();

  /// Extract kept existing image paths in current order
  List<String> get keptExistingPaths =>
      images.value.whereType<ExistingImageItem>().map((final e) => e.path).toList();

  String? get effectiveMaterial => _effectiveMaterial();

  String? get effectiveFit => _effectiveFit();

  String? _effectiveMaterial() {
    if (selectedMaterialPreset.value == kOtherSentinel) {
      final custom = materialOtherController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return selectedMaterialPreset.value;
  }

  String? _effectiveFit() {
    if (selectedFitPreset.value == kOtherSentinel) {
      final custom = fitOtherController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return selectedFitPreset.value;
  }

  CreateProductParams toCreateProductParams({
    required final String storeId,
    required final List<CreateProductSizeParams>? sizes,
  }) {
    return CreateProductParams(
      storeId: storeId,
      name: nameController.text,
      categoryIds: selectedCategoryIds.value.toList(),
      price: double.tryParse(priceController.text) ?? 0.0,
      images: newImageFiles,
      purchaseLink: purchaseLinkController.text.isNotEmpty
          ? purchaseLinkController.text
          : null,
      material: _effectiveMaterial(),
      elasticity: selectedElasticity.value,
      fit: _effectiveFit(),
      thickness: selectedThickness.value,
      styles: selectedStyles.value,
      seasons: selectedSeasons.value,
      sizes: sizes,
    );
  }

  Product toProduct({
    required final String id,
    required final String storeId,
    required final List<String> imagePaths,
    required final List<String> imageUrls,
    required final List<ProductSize>? sizes,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) {
    return Product(
      storeId: storeId,
      name: nameController.text,
      categoryIds: selectedCategoryIds.value.toList(),
      price: double.tryParse(priceController.text) ?? 0.0,
      purchaseLink: purchaseLinkController.text,
      material: _effectiveMaterial(),
      elasticity: selectedElasticity.value,
      fit: _effectiveFit(),
      thickness: selectedThickness.value,
      styles: selectedStyles.value,
      seasons: selectedSeasons.value,
      imagePaths: imagePaths,
      imageUrls: imageUrls,
      id: id,
      sizes: sizes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

String? _initialFitPreset(final String? fitValue) {
  if (fitValue == null) return null;
  return kFitPresets.contains(fitValue) ? fitValue : kOtherSentinel;
}

String _initialFitOtherText(final String? fitValue) {
  if (fitValue == null) return '';
  return kFitPresets.contains(fitValue) ? '' : fitValue;
}

String? _initialMaterialPreset(final String? materialValue) {
  if (materialValue == null) return null;
  return kMaterialPresets.contains(materialValue) ? materialValue : kOtherSentinel;
}

String _initialMaterialOtherText(final String? materialValue) {
  if (materialValue == null) return '';
  return kMaterialPresets.contains(materialValue) ? '' : materialValue;
}

ProductFormData useProductForm({final Product? initialProduct}) {
  final formKey = useMemoized(GlobalKey<FormState>.new);
  final nameController = useTextEditingController(text: initialProduct?.name);
  final priceController = useTextEditingController(
    text: initialProduct?.price.toString(),
  );
  final purchaseLinkController = useTextEditingController(
    text: initialProduct?.purchaseLink,
  );
  final materialOtherController = useTextEditingController(
    text: _initialMaterialOtherText(initialProduct?.material),
  );
  final selectedMaterialPreset = useValueNotifier<String?>(
    _initialMaterialPreset(initialProduct?.material),
  );
  final fitOtherController = useTextEditingController(
    text: _initialFitOtherText(initialProduct?.fit),
  );
  final selectedFitPreset = useValueNotifier<String?>(
    _initialFitPreset(initialProduct?.fit),
  );

  final initialImages = useMemoized(() {
    if (initialProduct == null) return <ImageItem>[];
    final paths = initialProduct.imagePaths;
    final urls = initialProduct.imageUrls;
    return List.generate(
      paths.length,
      (final i) => ImageItem.existing(path: paths[i], url: urls[i]),
    );
  });

  final images = useState<List<ImageItem>>(initialImages);

  final selectedCategoryIds = useValueNotifier<Set<String>>(
    initialProduct?.categoryIds.toSet() ?? {},
  );
  final selectedElasticity = useValueNotifier<ProductElasticity?>(
    initialProduct?.elasticity,
  );
  final selectedThickness = useValueNotifier<ProductThickness?>(
    initialProduct?.thickness,
  );
  final selectedStyles = useValueNotifier<List<ClothingStyle>?>(initialProduct?.styles);
  final selectedSeasons = useValueNotifier<List<ProductSeason>?>(initialProduct?.seasons);

  return ProductFormData(
    formKey: formKey,
    nameController: nameController,
    priceController: priceController,
    purchaseLinkController: purchaseLinkController,
    selectedMaterialPreset: selectedMaterialPreset,
    materialOtherController: materialOtherController,
    selectedFitPreset: selectedFitPreset,
    fitOtherController: fitOtherController,
    images: images,
    selectedCategoryIds: selectedCategoryIds,
    selectedElasticity: selectedElasticity,
    selectedThickness: selectedThickness,
    selectedStyles: selectedStyles,
    selectedSeasons: selectedSeasons,
  );
}
