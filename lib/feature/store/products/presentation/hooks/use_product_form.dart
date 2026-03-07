import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

class ProductFormData {
  ProductFormData({
    required this.formKey,
    required this.nameController,
    required this.priceController,
    required this.purchaseLinkController,
    required this.materialController,
    required this.selectedImage,
    required this.selectedCategoryId,
    required this.selectedElasticity,
    required this.selectedFit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchaseLinkController;
  final TextEditingController materialController;
  final ValueNotifier<File?> selectedImage;
  final ValueNotifier<String?> selectedCategoryId;
  final ValueNotifier<ProductElasticity?> selectedElasticity;
  final ValueNotifier<ProductFit?> selectedFit;

  bool validate(final BuildContext context) {
    return formKey.currentState?.validate() ?? false;
  }

  Product toProduct({
    required final String id,
    required final String storeId,
    required final String imagePath,
    required final String imageUrl,
    required final List<ProductSize>? sizes,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) {
    return Product(
      storeId: storeId,
      name: nameController.text,
      categoryId: selectedCategoryId.value ?? '',
      price: double.tryParse(priceController.text) ?? 0.0,
      purchaseLink: purchaseLinkController.text,
      material: materialController.text,
      elasticity: selectedElasticity.value,
      fit: selectedFit.value,
      imagePath: imagePath,
      imageUrl: imageUrl,
      id: id,
      sizes: sizes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
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
  final materialController = useTextEditingController(text: initialProduct?.material);

  final selectedImage = useState<File?>(null);
  final selectedCategoryId = useValueNotifier<String?>(initialProduct?.categoryId);
  final selectedElasticity = useValueNotifier<ProductElasticity?>(
    initialProduct?.elasticity,
  );
  final selectedFit = useValueNotifier<ProductFit?>(initialProduct?.fit);

  return ProductFormData(
    formKey: formKey,
    nameController: nameController,
    priceController: priceController,
    purchaseLinkController: purchaseLinkController,
    materialController: materialController,
    selectedImage: selectedImage,
    selectedCategoryId: selectedCategoryId,
    selectedElasticity: selectedElasticity,
    selectedFit: selectedFit,
  );
}
