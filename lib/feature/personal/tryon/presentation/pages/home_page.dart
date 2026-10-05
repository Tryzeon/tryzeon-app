import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/extensions/refresh_feedback_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/crop_options.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/actions/edit_outfit.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/coordinators/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/home_primary_action_button.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/page_linked_reveal.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_avatar_badge.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_avatar_page.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_disclaimer.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_gallery.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_gallery_actions.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_indicator.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_outfit_rail.dart';
import 'package:typed_result/typed_result.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final avatarAsync = ref.watch(avatarFileProvider);
    // Only surface an error once it settles with no photo to fall back on.
    final avatarError = avatarAsync.isLoading || avatarAsync.hasValue
        ? null
        : avatarAsync.error;
    final hasAvatar =
        ref.watch(userProfileProvider).value?.avatarPath?.isNotEmpty ?? false;
    final galleryState = ref.watch(tryonGalleryProvider);
    final galleryNotifier = ref.read(tryonGalleryProvider.notifier);
    final uploadingAvatarFile = ref.watch(avatarUploadProvider);
    final pageController = usePageController(initialPage: 0);

    final colorScheme = Theme.of(context).colorScheme;

    // The scrims and white chrome are for photos; a page with no photo sits
    // on the plain surface instead.
    final isBlankAvatarPage =
        galleryState.isAvatarPage &&
        (uploadingAvatarFile ?? avatarAsync.value) == null;

    final currentPage = galleryState.currentPage;
    final isCurrentTheAvatar = galleryState.isCurrentTheAvatar;

    useEffect(() {
      if (pageController.hasClients &&
          pageController.page?.round() != currentPage) {
        pageController.animateToPage(
          currentPage,
          duration: AppDuration.slow,
          curve: AppCurves.standard,
        );
      }
      return null;
    }, [currentPage]);

    void onAvatarReplaced(final Result<void, Failure> result) {
      if (!context.mounted) return;
      if (result.isFailure) {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
        return;
      }
      galleryNotifier.avatarReplaced();
    }

    Future<void> uploadAvatar() async {
      if (ref.read(avatarUploadProvider) != null) return;
      final File? imageFile = await ImagePickerHelper.pickImage(
        context,
        title: '選擇模特來源',
        hint: '建議上傳短袖短褲的正面全身照，雙手自然下垂、手上不要拿手機等物品。',
        crop: const LockedCrop(
          ratio: AppConstants.avatarAspectRatio,
          title: '框出全身',
        ),
      );
      if (imageFile == null) return;
      onAvatarReplaced(
        await ref.read(avatarUploadProvider.notifier).upload(imageFile),
      );
    }

    void handleTryonOutcome(final TryonOutcome outcome) {
      if (!context.mounted) return;
      switch (outcome) {
        case TryonSucceeded():
          HapticFeedback.heavyImpact();
        case TryonAvatarMissing():
          TopNotification.show(context, message: '請先選擇試穿模特才能開始試穿呦！');
        case TryonRateLimited(:final isVideo):
          UpgradeDialog.show(
            context,
            title: isVideo ? '影片試穿次數已達上限' : '試穿次數已達上限',
            content: isVideo
                ? '您的今日影片試穿次數已達上限\n升級至更高方案以獲得更多影片次數！'
                : '您的今日試穿次數已達上限\n升級至更高方案以獲得更多次數！',
          );
        case TryonFailed(:final failure):
          TopNotification.show(
            context,
            message: failure.displayMessage(context),
          );
      }
    }

    ref.listen(tryonControllerProvider, (final _, final outcome) {
      if (outcome != null) handleTryonOutcome(outcome);
    });

    Future<void> tryonFromLocal(final TryonMode mode) async {
      final File? garmentImage = await ImagePickerHelper.pickImage(
        context,
        title: '選擇服飾來源',
        hint: '建議上傳乾淨背景、單件服飾的清晰照片。',
      );
      if (garmentImage == null) return;

      await ref.read(tryonCoordinatorProvider).tryonFromOutfit([
        OutfitPiece.local(path: garmentImage.path),
      ], mode: mode);
    }

    void startTryon() {
      HapticFeedback.mediumImpact();
      TryonModeSheet.show(context: context, onModeSelected: tryonFromLocal);
    }

    final bottomOffset =
        MediaQuery.paddingOf(context).bottom + AppSpacing.bottomNavBarOverlap;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: hasAvatar
          ? Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.bottomNavBarOverlap),
              child: PageLinkedReveal(
                controller: pageController,
                interval: const Interval(0, 0.5),
                showOnAvatarPage: true,
                child: HomePrimaryActionButton(
                  label: '虛擬試穿',
                  icon: Image.asset(
                    AppConstants.logoMark,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  isDisabled: uploadingAvatarFile != null,
                  onTap: startTryon,
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => [
          ref.read(userProfileProvider.notifier).refresh(),
        ].showFirstFailure(context),
        edgeOffset: MediaQuery.of(context).padding.top,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image Layer — wrapped in scrollable for RefreshIndicator
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: avatarError != null
                    ? Center(
                        child: ErrorView(
                          message: avatarError.displayMessage(context),
                          onRetry: () => ref.invalidate(userProfileProvider),
                        ),
                      )
                    : TryonGallery(
                        pageController: pageController,
                        onPageChanged: galleryNotifier.setCurrentPage,
                        entries: galleryState.entries,
                        avatarPage: TryonAvatarPage(
                          onUploadOwnPhoto: uploadAvatar,
                          onPresetSelected: (final preset) async =>
                              onAvatarReplaced(
                                await ref
                                    .read(avatarUploadProvider.notifier)
                                    .applyPreset(preset),
                              ),
                        ),
                        showScrims: !isBlankAvatarPage,
                      ),
              ),
            ),

            // 2. Top Left — Tryzeon Logo (transparent mark)
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              left: AppSpacing.lg,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppConstants.logoMark,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Tryzeon',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isBlankAvatarPage
                          ? colorScheme.onSurface
                          : colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Top Right — Avatar Badge + More Options (parallel). Always up:
            // the sheet adapts its actions to the page in view.
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
              right: AppSpacing.md,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isBlankAvatarPage) ...[
                    TryonAvatarBadge(isVisible: isCurrentTheAvatar),
                    const SizedBox(width: AppSpacing.sm),
                    TryonGalleryActions(onReplaceAvatar: uploadAvatar),
                  ],
                ],
              ),
            ),

            if (galleryState.currentEntry case final entry?
                when entry.pieces.isNotEmpty)
              Positioned(
                right: AppSpacing.lg,
                bottom: bottomOffset + AppSpacing.md,
                child: PageLinkedReveal(
                  controller: pageController,
                  interval: const Interval(0.5, 1),
                  child: TryonOutfitRail(
                    pieces: entry.pieces,
                    onEdit: () => editOutfit(context, ref, entry),
                  ),
                ),
              ),

            // 4. Bottom Left — Indicator (white floating lines) with the AI
            // disclaimer as the last element on the page, so it reads as a
            // footnote rather than a caption for the indicator. The group hangs
            // from a lower anchor to leave the indicator where it was.
            if (galleryState.entries.isNotEmpty)
              Positioned(
                bottom: bottomOffset + AppSpacing.smMd,
                left: AppSpacing.xxl,
                child: PageLinkedReveal(
                  controller: pageController,
                  interval: const Interval(0.5, 1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TryonIndicator(
                        currentTryonIndex: galleryState.currentIndex,
                        tryonImagesCount: galleryState.entries.length,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const TryonDisclaimer(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
