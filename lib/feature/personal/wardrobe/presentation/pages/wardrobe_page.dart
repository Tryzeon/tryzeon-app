import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/extensions/refresh_feedback_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/actions/wardrobe_outfit_actions.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/dialogs/wardrobe_full_dialog.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../sheets/upload_wardrobe_item_sheet.dart';
import '../widgets/wardrobe_item_card.dart';

class WardrobePage extends HookConsumerWidget {
  const WardrobePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 1. Data Providers
    final wardrobeItemsAsync = ref.watch(wardrobeItemsProvider);
    final capacity = ref.watch(wardrobeCapacityProvider).value;
    final isComposing = ref.watch(
      outfitTrayProvider.select((final s) => s.isOpen),
    );
    final selectedIds = ref.watch(
      outfitTrayProvider.select(
        (final s) => s.pieces.map((final p) => p.id).toSet(),
      ),
    );

    // 2. State
    final selectedGarmentType = useState<GarmentType?>(null);
    final garmentTypeScrollController = useScrollController();

    // 3. Theme
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // 4. Actions
    Future<void> showUploadSheet() async {
      if (capacity?.isFull ?? false) {
        await showWardrobeFullDialog(context);
        return;
      }

      final File? image = await ImagePickerHelper.pickImage(context);

      if (image != null && context.mounted) {
        final uploadedGarmentType = await UploadWardrobeItemSheet.show(
          context: context,
          image: image,
        );

        if (uploadedGarmentType != null) {
          if (selectedGarmentType.value != null) {
            selectedGarmentType.value = uploadedGarmentType;
          }
        }
      }
    }

    void enterCompose() => ref.read(outfitTrayProvider.notifier).open();

    void exitCompose() => ref.read(outfitTrayProvider.notifier).close();

    // 5. Widget Helpers
    Widget buildGarmentTypeChip(final GarmentType? type) {
      final isSelected = selectedGarmentType.value == type;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(
          label: Text(type?.displayName ?? '全部'),
          selected: isSelected,
          onSelected: (final selected) => selectedGarmentType.value = type,
        ),
      );
    }

    Widget buildGarmentTypeBar() {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: SingleChildScrollView(
          controller: garmentTypeScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (final type in [null, ...GarmentType.values])
                buildGarmentTypeChip(type),
            ],
          ),
        ),
      );
    }

    Widget buildComposeButton() {
      return isComposing
          ? TextButton.icon(
              key: const Key('wardrobe-compose-cancel'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: exitCompose,
              icon: const Icon(Icons.close_rounded),
              label: const Text('取消'),
            )
          : TextButton.icon(
              key: const Key('wardrobe-compose-start'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: enterCompose,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('搭配'),
            );
    }

    Widget buildEmptyState() {
      return LayoutBuilder(
        builder: (final context, final constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.checkroom_rounded,
                        size: AppSpacing.xxl,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('此分類沒有衣物', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isComposing ? '試試其他分類，或結束搭配後上傳' : '點擊右下角 + 上傳第一件衣服',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final totalCount = wardrobeItemsAsync.value?.length ?? 0;
    final isNearLimit = capacity?.isNearLimit ?? false;
    final countLabel = isNearLimit
        ? '${capacity!.used} / ${capacity.limit} 件'
        : '$totalCount 件衣物';

    return PopScope(
      canPop: !isComposing,
      onPopInvokedWithResult: (final didPop, final _) {
        if (!didPop) exitCompose();
      },
      child: Scaffold(
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.bottomNavBarOverlap),
          child: AnimatedScale(
            scale: isComposing ? 0 : 1,
            duration: AppDuration.standard,
            curve: AppCurves.standard,
            child: FloatingActionButton(
              onPressed: isComposing ? null : showUploadSheet,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('我的衣櫃', style: textTheme.headlineMedium),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            countLabel,
                            style: textTheme.bodySmall?.copyWith(
                              color: isNearLimit
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    buildComposeButton(),
                  ],
                ),
              ),

              buildGarmentTypeBar(),

              // Grid Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => [
                    ref.read(wardrobeItemsProvider.notifier).refresh(),
                  ].showFirstFailure(context),
                  child: wardrobeItemsAsync.when(
                    skipLoadingOnReload: true,
                    skipError: true,
                    data: (final wardrobeItems) {
                      final filtered = selectedGarmentType.value == null
                          ? wardrobeItems
                          : wardrobeItems
                                .where(
                                  (final i) =>
                                      i.garmentType ==
                                      selectedGarmentType.value,
                                )
                                .toList();

                      if (filtered.isEmpty) return buildEmptyState();

                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          MediaQuery.of(context).padding.bottom +
                              AppSpacing.fabClearance +
                              AppSpacing.bottomNavBarOverlap,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: AppSpacing.sm,
                              mainAxisSpacing: AppSpacing.sm,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (final context, final index) {
                          final item = filtered[index];
                          return WardrobeItemCard(
                            item: item,
                            isSelected: selectedIds.contains(item.id),
                            onTap: () => isComposing
                                ? toggleOutfitPiece(
                                    ref,
                                    outfitPieceFromWardrobeItem(item),
                                  )
                                : context.push(
                                    AppRoutes.personalWardrobeItemPath(item.id),
                                  ),
                            onLongPress: () => toggleOutfitPiece(
                              ref,
                              outfitPieceFromWardrobeItem(item),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (final error, final stack) => ErrorView(
                      message: error.displayMessage(context),
                      onRetry: () => ref.invalidate(wardrobeItemsProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
