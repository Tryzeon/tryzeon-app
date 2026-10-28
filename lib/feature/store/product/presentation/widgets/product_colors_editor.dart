import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/presentation/widgets/app_action_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/lifted_reorder_proxy.dart';
import 'package:tryzeon/core/presentation/widgets/selection_form_field.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_rules.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/presentation/controllers/product_color_entry_controller.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_color_manager.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_form_section_label.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_image_editor.dart';

const _cardInset = AppSpacing.smMd;
const _expandDuration = AppDuration.standard;
const _swatchSize = 40.0;

class ProductColorsEditor extends HookWidget {
  const ProductColorsEditor({
    super.key,
    required this.manager,
    required this.onPickImage,
  });

  final ProductColorManager manager;
  final Future<List<File>?> Function(int remainingCount) onPickImage;

  @override
  Widget build(final BuildContext context) {
    final entries = manager.entries;
    useListenable(
      useMemoized(
        () => Listenable.merge([
          for (final entry in entries) entry.nameController,
        ]),
        [entries],
      ),
    );

    Future<void> addColor() async {
      final images = await _pickImageItems(
        context,
        onPickImage,
        AppConstants.maxProductImages,
      );
      if (images == null) return;
      manager.addColor(images: images);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.smMd,
          ),
          child: ProductFormSectionLabel(
            number: '01',
            title: '顏色與照片',
            helper: manager.isSingle
                ? '第一張照片用於 AI 試穿，請放完整正面照'
                : '每個顏色的第一張照片用於 AI 試穿，請放完整正面照',
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: liftedReorderProxy,
          itemCount: entries.length,
          onReorderItem: manager.reorder,
          itemBuilder: (final context, final index) {
            final entry = entries[index];
            return _ColorBlock(
              key: entry.key,
              entry: entry,
              index: index,
              manager: manager,
              onPickImage: onPickImage,
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextButton.icon(
            onPressed: manager.canAddColor ? () => unawaited(addColor()) : null,
            icon: const Icon(Icons.add_rounded),
            label: Text(switch ((manager.canAddColor, manager.isSingle)) {
              (false, _) => '最多 ${AppConstants.maxProductColors} 個顏色',
              (true, true) => '新增其他顏色',
              (true, false) => '新增顏色',
            }),
          ),
        ),
      ],
    );
  }
}

class _ColorBlock extends HookWidget {
  const _ColorBlock({
    super.key,
    required this.entry,
    required this.index,
    required this.manager,
    required this.onPickImage,
  });

  final ProductColorEntryController entry;
  final int index;
  final ProductColorManager manager;
  final Future<List<File>?> Function(int remainingCount) onPickImage;

  @override
  Widget build(final BuildContext context) {
    useValueListenable(entry.images);
    final nameSuggestion = useValueListenable(entry.nameSuggestion);
    final isAnalyzing = nameSuggestion == ColorNameSuggestion.pending;
    final isCover = index == 0;

    final isSingle = manager.isSingle;
    final isExpanded = manager.isExpanded(entry);
    final issues = manager.issuesOf(entry);

    final revealRequest = manager.revealRequest?.entry == entry
        ? manager.revealRequest
        : null;

    final expansion = useAnimationController(
      duration: _expandDuration,
      initialValue: isExpanded && revealRequest == null ? 1 : 0,
    );
    final sizeFactor = useMemoized(
      () => expansion.drive(CurveTween(curve: AppCurves.standard)),
      [expansion],
    );
    final isDismissed = useListenableSelector(
      expansion,
      () => expansion.isDismissed,
    );
    final isClosed = isDismissed && !isExpanded;
    useEffect(() {
      unawaited(isExpanded ? expansion.forward() : expansion.reverse());
      return null;
    }, [isExpanded]);
    useEffect(() {
      if (revealRequest == null) return null;
      final settled = isExpanded ? expansion.forward() : expansion.reverse();
      unawaited(settled.then((_) => _revealAfterLayout(entry)));
      return null;
    }, [revealRequest]);

    Future<void> pickImages() async {
      final remaining =
          AppConstants.maxProductImages - entry.images.value.length;
      if (remaining <= 0) return;
      final picked = await _pickImageItems(context, onPickImage, remaining);
      if (picked == null) return;
      entry.images.value = [...entry.images.value, ...picked];
    }

    final inset = isSingle ? AppSpacing.lg : _cardInset;
    final body = Padding(
      padding: isSingle
          ? EdgeInsets.zero
          : const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColorImagesField(
            entry: entry,
            manager: manager,
            isCover: isCover,
            showsCount: isSingle,
            inset: inset,
            onPickImage: pickImages,
          ),
          if (isSingle && isAnalyzing)
            Padding(
              padding: EdgeInsets.fromLTRB(inset, AppSpacing.sm, inset, 0),
              child: _AnalyzingIndicator(isCover: isCover),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(inset, AppSpacing.md, inset, 0),
            child: _ColorNameField(
              entry: entry,
              manager: manager,
              suggestion: nameSuggestion,
              isOptional: isSingle,
            ),
          ),
        ],
      ),
    );

    final theme = Theme.of(context);
    final showsIssues = !isSingle && manager.showsIssues && issues.isNotEmpty;
    final cardPadding = isSingle ? 0.0 : AppSpacing.lg;

    // A lone colour keeps the Card, styled away, so its fields keep their
    // state when a second colour turns it into a card.
    return Padding(
      padding: EdgeInsets.fromLTRB(cardPadding, 0, cardPadding, AppSpacing.sm),
      child: Card(
        color: isSingle ? Colors.transparent : null,
        clipBehavior: Clip.antiAlias,
        shape: switch ((isSingle, showsIssues)) {
          (true, _) => const RoundedRectangleBorder(),
          (false, true) => (theme.cardTheme.shape! as OutlinedBorder).copyWith(
            side: BorderSide(color: theme.colorScheme.error),
          ),
          (false, false) => null,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSingle)
              _ColorHeader(
                entry: entry,
                index: index,
                manager: manager,
                issues: issues,
                isExpanded: isExpanded,
                isAnalyzing: isAnalyzing,
                onTap: () =>
                    isExpanded ? manager.collapse() : manager.expand(entry),
              ),
            SizeTransition(
              sizeFactor: sizeFactor,
              alignment: Alignment.topCenter,
              child: isClosed ? const SizedBox(width: double.infinity) : body,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorHeader extends StatelessWidget {
  const _ColorHeader({
    required this.entry,
    required this.index,
    required this.manager,
    required this.issues,
    required this.isExpanded,
    required this.isAnalyzing,
    required this.onTap,
  });

  final ProductColorEntryController entry;
  final int index;
  final ProductColorManager manager;
  final List<ColorIssue> issues;
  final bool isExpanded;
  final bool isAnalyzing;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = normalizeColorName(entry.nameController.text);
    final isCover = index == 0;
    final images = entry.images.value;
    final listsIssues = !isExpanded && issues.isNotEmpty;
    final swatch = _ColorSwatch(image: images.firstOrNull);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(index: index, isEnabled: !isExpanded),
          if (isCover && !isExpanded)
            CoachMarkAnchor(
              target: CoachMarkTarget.productImages,
              child: swatch,
            )
          else
            swatch,
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              name ?? '未命名顏色',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: name == null
                  ? TextStyle(color: colorScheme.onSurfaceVariant)
                  : null,
            ),
          ),
          if (isCover) ...[
            const SizedBox(width: AppSpacing.sm),
            const _CoverTag(),
          ],
        ],
      ),
      subtitle: isAnalyzing
          ? Align(
              alignment: Alignment.centerLeft,
              child: _AnalyzingIndicator(isCover: isCover),
            )
          : Text(
              listsIssues
                  ? issues.map(_issueText).join(' · ')
                  : photoCountLabel(images.length),
              style: listsIssues && manager.showsIssues
                  ? TextStyle(color: colorScheme.error)
                  : null,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ColorMenuButton(entry: entry, index: index, manager: manager),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: _expandDuration,
              curve: AppCurves.standard,
              child: Icon(
                Icons.expand_more_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverTag extends StatelessWidget {
  const _CoverTag();

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: AppRadius.pillAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          '封面',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _ColorNameField extends StatelessWidget {
  const _ColorNameField({
    required this.entry,
    required this.manager,
    required this.suggestion,
    required this.isOptional,
  });

  final ProductColorEntryController entry;
  final ProductColorManager manager;
  final ColorNameSuggestion suggestion;
  final bool isOptional;

  @override
  Widget build(final BuildContext context) {
    final isEmpty = normalizeColorName(entry.nameController.text) == null;
    final helper = switch (suggestion) {
      _ when entry.showsSuggestedName => 'AI 依照片建議，可直接修改',
      ColorNameSuggestion.unavailable when isEmpty => 'AI 未能判斷顏色，請手動輸入',
      _ => null,
    };

    return TextFormField(
      controller: entry.nameController,
      decoration: InputDecoration(
        labelText: isOptional ? '顏色名稱（選填）' : '顏色名稱',
        hintText: '例：霧灰',
        helperText: helper,
        counterText: '',
      ),
      maxLength: maxColorNameLength,
      textInputAction: TextInputAction.done,
      autovalidateMode: manager.showsIssues
          ? AutovalidateMode.always
          : AutovalidateMode.onUserInteractionIfError,
      validator: (final _) => switch (manager.nameIssueOf(entry)) {
        final issue? => _issueText(issue),
        null => null,
      },
    );
  }
}

class _ColorImagesField extends StatelessWidget {
  const _ColorImagesField({
    required this.entry,
    required this.manager,
    required this.isCover,
    required this.showsCount,
    required this.inset,
    required this.onPickImage,
  });

  final ProductColorEntryController entry;
  final ProductColorManager manager;
  final bool isCover;
  final bool showsCount;
  final double inset;
  final VoidCallback onPickImage;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return SelectionFormField<List<ImageItem>>(
      controller: entry.images,
      autovalidateMode: manager.showsIssues
          ? AutovalidateMode.always
          : AutovalidateMode.onUserInteraction,
      validator: (final _) => switch (manager.photoIssueOf(entry)) {
        ColorIssue.missingImages => '請為這個顏色選擇至少一張照片',
        final issue? => _issueText(issue),
        null => null,
      },
      builder: (final state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImageEditor(
            images: entry.images.value,
            hasError: state.hasError,
            hostsCoachMark: isCover,
            horizontalPadding: inset,
            showsCount: showsCount,
            onImagesChanged: (final updated) => entry.images.value = updated,
            onPickImage: onPickImage,
          ),
          if (state.errorText case final errorText?)
            Padding(
              padding: EdgeInsets.fromLTRB(inset, AppSpacing.sm, inset, 0),
              child: Text(
                errorText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorMenuButton extends StatelessWidget {
  const _ColorMenuButton({
    required this.entry,
    required this.index,
    required this.manager,
  });

  final ProductColorEntryController entry;
  final int index;
  final ProductColorManager manager;

  Future<void> _confirmRemove(
    final BuildContext context,
    final String? name,
  ) async {
    final result = await showAppOkCancelDialog(
      context: context,
      title: name == null ? '刪除這個顏色？' : '刪除「$name」？',
      message: '這個顏色的照片和名稱會一起刪除。',
      okLabel: '刪除',
      cancelLabel: '取消',
      isDestructiveAction: true,
    );
    if (result == OkCancelResult.ok) manager.removeColor(entry);
  }

  @override
  Widget build(final BuildContext context) {
    final name = normalizeColorName(entry.nameController.text);
    return IconButton(
      tooltip: '更多操作',
      icon: const Icon(Icons.more_horiz),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: () => showAppActionSheet(
        context,
        title: name,
        actions: [
          if (index > 0)
            AppMenuAction(
              icon: Icons.vertical_align_top_rounded,
              title: '設為封面',
              onTap: () => manager.reorder(index, 0),
            ),
          AppMenuAction(
            icon: Icons.delete_outline_rounded,
            title: '刪除顏色',
            onTap: () => unawaited(_confirmRemove(context, name)),
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.index, required this.isEnabled});

  final int index;
  final bool isEnabled;

  @override
  Widget build(final BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return ReorderableDragStartListener(
      index: index,
      enabled: isEnabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Icon(
          Icons.drag_indicator_rounded,
          color: isEnabled ? color : color.withValues(alpha: AppOpacity.strong),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.image});

  final ImageItem? image;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = this.image;

    return SizedBox.square(
      dimension: _swatchSize,
      child: ClipRRect(
        borderRadius: AppRadius.buttonAll,
        child: image == null
            ? ColoredBox(
                color: colorScheme.surfaceContainerHigh,
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : ProductImageView(item: image, size: _swatchSize),
      ),
    );
  }
}

class _AnalyzingIndicator extends StatelessWidget {
  const _AnalyzingIndicator({required this.isCover});

  final bool isCover;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final indicator = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'AI 分析中…',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return isCover
        ? CoachMarkAnchor(
            target: CoachMarkTarget.productImageAnalyzing,
            child: indicator,
          )
        : indicator;
  }
}

String _issueText(final ColorIssue issue) => switch (issue) {
  ColorIssue.missingImages => '還沒有照片',
  ColorIssue.tooManyImages => '照片最多 ${AppConstants.maxProductImages} 張',
  ColorIssue.missingName => '請輸入顏色名稱',
  ColorIssue.nameTooLong => '顏色名稱最多 $maxColorNameLength 字',
  ColorIssue.duplicateName => '顏色名稱重複',
};

Future<List<ImageItem>?> _pickImageItems(
  final BuildContext context,
  final Future<List<File>?> Function(int remainingCount) onPickImage,
  final int remainingCount,
) async {
  final files = await onPickImage(remainingCount);
  if (!context.mounted || files == null || files.isEmpty) return null;
  return [for (final file in files) ImageItem.newImage(file: file)];
}

Future<void> _revealAfterLayout(final ProductColorEntryController entry) async {
  await WidgetsBinding.instance.endOfFrame;
  entry.key.currentContext?.findRenderObject()?.showOnScreen(
    duration: AppDuration.slow,
    curve: AppCurves.standard,
  );
}
