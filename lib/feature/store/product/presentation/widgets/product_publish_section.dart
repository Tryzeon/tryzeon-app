import 'package:flutter/material.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_status_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_form_section_label.dart';

class ProductPublishSection extends StatelessWidget {
  const ProductPublishSection({super.key, required this.status});

  final ValueNotifier<ProductStatus> status;

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ProductFormSectionLabel(number: '04', title: '上架設定'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ValueListenableBuilder<ProductStatus>(
          valueListenable: status,
          builder: (final context, final value, final _) => CoachMarkAnchor(
            target: CoachMarkTarget.productPublish,
            child: SwitchListTile(
              title: const Text('上架到商店'),
              subtitle: Text(value.description),
              value: value == ProductStatus.active,
              onChanged: (final on) => status.value = on
                  ? ProductStatus.active
                  : ProductStatus.archived,
            ),
          ),
        ),
      ],
    );
  }
}
