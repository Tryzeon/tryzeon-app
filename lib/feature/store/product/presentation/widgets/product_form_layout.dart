import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_color_manager.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_form.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_size_voice_input.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_advanced_fields_editor.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_basic_fields_editor.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_colors_editor.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_form_section_label.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_publish_section.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_size_matrix_editor.dart';

class ProductFormLayout extends StatelessWidget {
  const ProductFormLayout({
    required this.formData,
    required this.colorManager,
    required this.sizeManager,
    required this.onPickImage,
    required this.productCategoriesAsync,
    required this.onRetryCategories,
    required this.voiceStatus,
    required this.onVoicePressed,
    this.advancedController,
    super.key,
  });
  final ProductFormData formData;
  final ProductColorManager colorManager;
  final ProductSizeManager sizeManager;
  final Future<List<File>?> Function(int remainingCount) onPickImage;
  final AsyncValue<List<ProductCategory>> productCategoriesAsync;
  final VoidCallback onRetryCategories;
  final SizeVoiceStatus voiceStatus;
  final VoidCallback onVoicePressed;
  final ExpansibleController? advancedController;

  @override
  Widget build(final BuildContext context) {
    return Form(
      key: formData.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductColorsEditor(manager: colorManager, onPickImage: onPickImage),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ProductFormSectionLabel(number: '02', title: '商品資訊'),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductBasicFieldsEditor(
                  nameController: formData.nameController,
                  priceController: formData.priceController,
                  purchaseLinkController: formData.purchaseLinkController,
                  descriptionController: formData.descriptionController,
                  selectedGender: formData.selectedGender,
                  selectedCategoryId: formData.selectedCategoryId,
                  onCategorySelected: formData.selectCategory,
                  productCategoriesAsync: productCategoriesAsync,
                  onRetryCategories: onRetryCategories,
                ),
                const SizedBox(height: AppSpacing.lg),
                ProductAdvancedFieldsEditor(
                  selectedMaterial: formData.selectedMaterial,
                  selectedFit: formData.selectedFit,
                  selectedElasticity: formData.selectedElasticity,
                  selectedThickness: formData.selectedThickness,
                  selectedStyles: formData.selectedStyles,
                  selectedSeasons: formData.selectedSeasons,
                  controller: advancedController,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Expanded(
                  child: ProductFormSectionLabel(number: '03', title: '尺寸資訊'),
                ),
                CoachMarkAnchor(
                  target: CoachMarkTarget.productSizeVoice,
                  child: _SizeVoiceButton(
                    status: voiceStatus,
                    onPressed: onVoicePressed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ValueListenableBuilder<GarmentType?>(
              valueListenable: formData.selectedGarmentType,
              builder: (final context, final garmentType, final _) =>
                  ProductSizeMatrixEditor(
                    manager: sizeManager,
                    visibleTypes: formData.visibleMeasurementTypes,
                    garmentType: garmentType,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          ProductPublishSection(status: formData.status),
        ],
      ),
    );
  }
}

class _SizeVoiceButton extends StatelessWidget {
  const _SizeVoiceButton({required this.status, required this.onPressed});

  final SizeVoiceStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: status == SizeVoiceStatus.uploading ? null : onPressed,
      tooltip: status == SizeVoiceStatus.recording
          ? '錄音中，再按一下停止'
          : '語音輸入尺寸：例「M 號，胸寬五十公分，衣長七十二」',
      icon: switch (status) {
        SizeVoiceStatus.uploading => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: AppStroke.regular,
            color: colorScheme.onSurface,
          ),
        ),
        SizeVoiceStatus.recording => Icon(
          Icons.stop_circle_rounded,
          color: colorScheme.error,
        ),
        SizeVoiceStatus.idle => Icon(
          Icons.mic_none_rounded,
          color: colorScheme.onSurface,
        ),
      },
    );
  }
}
