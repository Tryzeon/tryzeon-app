import 'dart:convert';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gal/gal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/app_snack_bar.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/core/utils/image_watermark_helper.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/home_primary_action_button.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_gallery.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_indicator.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_more_options_button.dart';
import 'package:tryzeon/feature/personal/home/providers/home_providers.dart';
import 'package:tryzeon/feature/personal/main/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/providers/subscription_capabilities_provider.dart';
import 'package:typed_result/typed_result.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final avatarAsync = ref.watch(avatarFileProvider);
    final tryonImages = useState<List<TryonResult>>([]);
    final currentTryonIndex = useState(-1);
    final customAvatarIndex = useState<int?>(null);
    final isUploadingAvatar = useState(false);
    final pageController = usePageController(initialPage: 0);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Sync PageController with currentTryonIndex changes (from logic)
    useEffect(() {
      if (pageController.hasClients) {
        final targetPage = currentTryonIndex.value + 1;
        if (pageController.page?.round() != targetPage) {
          pageController.animateToPage(
            targetPage,
            duration: AppDuration.slow,
            curve: AppCurves.standard,
          );
        }
      }
      return null;
    }, [currentTryonIndex.value]);

    Future<void> uploadAvatar() async {
      final File? imageFile = await ImagePickerHelper.pickImage(context);
      if (imageFile == null) return;

      isUploadingAvatar.value = true;

      try {
        // Upload
        final profile = await ref.read(userProfileProvider.future);
        if (profile == null) return;

        final result = await ref.read(updateUserAvatarUseCaseProvider)(
          avatarFile: imageFile,
          previousAvatarPath: profile.avatarPath,
        );

        if (!context.mounted) return;

        if (result.isSuccess) {
          ref.invalidate(userProfileProvider);
          ref.invalidate(avatarFileProvider);
          await ref.read(avatarFileProvider.future);
        } else {
          TopNotification.show(
            context,
            message: result.getError()!.displayMessage(context),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to upload avatar', e, stackTrace);
        if (context.mounted) {
          TopNotification.show(
            context,
            message: '上傳照片失敗，請稍後再試',
          );
        }
      } finally {
        if (context.mounted) {
          isUploadingAvatar.value = false;
        }
      }
    }

    Future<void> performTryOn({
      final List<String>? clothesBase64s,
      final List<String>? clothesPaths,
      final TryOnMode mode = TryOnMode.image,
    }) async {
      // 0. Check if avatar is uploaded
      final avatarFile = ref.read(avatarFileProvider).value;
      if (avatarFile == null) {
        TopNotification.show(
          context,
          message: '請先上傳個人照片才能開始試穿呦！',
        );
        return;
      }

      // 1. Prepare Request Data
      String? customAvatarBase64;
      if (customAvatarIndex.value != null &&
          customAvatarIndex.value! < tryonImages.value.length) {
        final result = tryonImages.value[customAvatarIndex.value!];
        if (result.imageBase64 != null) {
          customAvatarBase64 = result.imageBase64!;
        }
      }

      // 2. Optimistic Update (Add Loading Placeholder)
      final requestId = UniqueKey().toString();
      final placeholderResult = TryonResult(id: requestId, mode: mode, isLoading: true);
      final placeholderIndex = tryonImages.value.length;
      tryonImages.value = [...tryonImages.value, placeholderResult];
      currentTryonIndex.value = placeholderIndex;

      // 3. API Call
      String? scenePrompt;
      String? transitionPrompt;
      if (mode == TryOnMode.video) {
        final promptConfig = await ref.read(videoPromptConfigProvider.future);
        scenePrompt = promptConfig.scenePrompt;
        transitionPrompt = promptConfig.transitionPrompt;
      }

      final profile = await ref.read(userProfileProvider.future);
      final String? defaultAvatarPath = profile?.avatarPath;

      final result = await ref
          .read(tryonActionProvider.notifier)
          .execute(
            TryOnParams(
              requestId: requestId,
              avatarBase64: customAvatarBase64,
              avatarPath: defaultAvatarPath,
              clothesBase64s: clothesBase64s,
              clothesPaths: clothesPaths,
              mode: mode,
              scenePrompt: scenePrompt,
              transitionPrompt: transitionPrompt,
            ),
          );

      if (!context.mounted) return;

      // 4. Handle Result
      if (result.isSuccess) {
        final resultIndex = tryonImages.value.indexWhere(
          (final result) => result.id == requestId,
        );
        if (resultIndex == -1) return;

        final tryonResult = result.get()!.copyWith(isLoading: false);
        tryonImages.value = [...tryonImages.value]..[resultIndex] = tryonResult;
        currentTryonIndex.value = resultIndex;

        HapticFeedback.heavyImpact();
      } else {
        // Failure: Remove placeholder
        final resultIndex = tryonImages.value.indexWhere(
          (final result) => result.id == requestId,
        );
        if (resultIndex == -1) return;

        tryonImages.value = [...tryonImages.value]..removeAt(resultIndex);
        currentTryonIndex.value = tryonImages.value.length - 1;

        final failure = result.getError()!;
        if (failure is RateLimitFailure) {
          final isVideo = mode == TryOnMode.video;
          UpgradeDialog.show(
            context,
            title: isVideo ? '影片試穿次數已達上限' : '試穿次數已達上限',
            content: isVideo
                ? '您的今日影片試穿次數已達上限\n升級至更高方案以獲得更多影片次數！'
                : '您的今日試穿次數已達上限\n升級至更高方案以獲得更多次數！',
          );
        } else {
          TopNotification.show(
            context,
            message: failure.displayMessage(context),
          );
        }
      }
    }

    Future<void> tryOnFromLocal() async {
      final File? clothesImage = await ImagePickerHelper.pickImage(context);
      if (clothesImage == null) return;

      final clothesBytes = await clothesImage.readAsBytes();
      final clothesBase64 = base64Encode(clothesBytes);
      performTryOn(clothesBase64s: [clothesBase64], mode: TryOnMode.image);
    }

    Future<void> tryOnFromStorage(
      final List<String> clothesPaths, {
      final TryOnMode mode = TryOnMode.image,
    }) async {
      performTryOn(clothesPaths: clothesPaths, mode: mode);
    }

    Future<void> downloadVideo(final TryonResult result) async {
      if (result.videoUrl == null) {
        throw Exception('Video URL is missing');
      }

      // 1. Download to temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/tryon_${DateTime.now().millisecondsSinceEpoch}.mp4';

      try {
        final dio = Dio();
        await dio.download(result.videoUrl!, tempPath);

        // 2. Save to gallery
        await Gal.putVideo(tempPath);

        if (context.mounted) {
          AppSnackBar.show(context, message: '影片已儲存到相簿');
        }
      } finally {
        // 3. Clean up temp file
        final file = File(tempPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    Future<void> downloadImage(final TryonResult result) async {
      if (result.imageBase64 == null) {
        throw Exception('Image data is null');
      }

      final originalBytes = base64Decode(result.imageBase64!);
      Uint8List imageToSave = originalBytes;

      final capabilities = await ref.read(subscriptionCapabilitiesProvider.future);
      if (capabilities.requiresWatermark) {
        imageToSave = await ImageWatermarkHelper.addWatermark(originalBytes);
      }

      await Gal.putImageBytes(
        imageToSave,
        name: 'tryzeon_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (context.mounted) {
        AppSnackBar.show(context, message: '照片已儲存到相簿');
      }
    }

    Future<void> downloadCurrentMedia() async {
      try {
        final result = tryonImages.value[currentTryonIndex.value];

        if (result.mode == TryOnMode.video) {
          await downloadVideo(result);
        } else {
          await downloadImage(result);
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to save media', e, stackTrace);
        if (context.mounted) {
          TopNotification.show(
            context,
            message: '儲存失敗，請檢查儲存權限',
          );
        }
      }
    }

    Future<void> toggleAvatar() async {
      final isCurrentlySet = customAvatarIndex.value == currentTryonIndex.value;

      if (isCurrentlySet) {
        customAvatarIndex.value = null;
      } else {
        customAvatarIndex.value = currentTryonIndex.value;
      }
    }

    Future<void> deleteCurrentTryon() async {
      final result = await showOkCancelAlertDialog(
        context: context,
        message: '確定要刪除這張試穿照片嗎？',
        okLabel: '刪除',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );

      if (result == OkCancelResult.ok) {
        final deletedIndex = currentTryonIndex.value;

        final newImages = List<TryonResult>.from(tryonImages.value);
        newImages.removeAt(deletedIndex);
        tryonImages.value = newImages;

        if (customAvatarIndex.value == deletedIndex) {
          customAvatarIndex.value = null;
        } else if (customAvatarIndex.value != null &&
            customAvatarIndex.value! > deletedIndex) {
          customAvatarIndex.value = customAvatarIndex.value! - 1;
        }

        if (tryonImages.value.isEmpty) {
          currentTryonIndex.value = -1;
        } else if (currentTryonIndex.value >= tryonImages.value.length) {
          currentTryonIndex.value = tryonImages.value.length - 1;
        }
      }
    }

    final coordinator = ref.read(tryOnCoordinatorProvider);
    useEffect(() {
      coordinator.bindTryOnFromStorage(tryOnFromStorage);
      return () => coordinator.unbindTryOnFromStorage(tryOnFromStorage);
    }, [coordinator]);

    final bottomOffset =
        MediaQuery.paddingOf(context).bottom +
        (PlatformInfo.isIOS26OrHigher() ? AppSpacing.bottomNavBarHeight : 0);

    final showMoreOptions =
        currentTryonIndex.value >= 0 &&
        !tryonImages.value[currentTryonIndex.value].isLoading;
    final showIndicator = currentTryonIndex.value >= 0;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () => refreshUserProfile(ref),
        edgeOffset: MediaQuery.of(context).padding.top,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image Layer — wrapped in scrollable for RefreshIndicator
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: avatarAsync.when(
                  skipLoadingOnReload: true,
                  skipError: true,
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (final error, final stack) => Center(
                    child: ErrorView(
                      message: error.displayMessage(context),
                      onRetry: () => refreshUserProfile(ref),
                    ),
                  ),
                  data: (final avatarFile) => TryOnGallery(
                    pageController: pageController,
                    onPageChanged: (final index) => currentTryonIndex.value = index - 1,
                    onUploadTap: uploadAvatar,
                    tryonResults: tryonImages.value,
                    currentTryonIndex: currentTryonIndex.value,
                    avatarFile: avatarFile,
                    isUploadingAvatar: isUploadingAvatar.value,
                  ),
                ),
              ),
            ),

            // 2. Top Left — Tryzeon Logo (Playfair Display italic)
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
              left: AppSpacing.xl,
              child: Text(
                'Tryzeon',
                style: textTheme.displaySmall?.copyWith(
                  color: colorScheme.onPrimary,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: colorScheme.shadow.withValues(alpha: AppOpacity.strong),
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Top Right — More Options (white ⋮ with shadow)
            if (showMoreOptions)
              Positioned(
                top: MediaQuery.paddingOf(context).top + AppSpacing.lg,
                right: AppSpacing.lg,
                child: TryOnMoreOptionsButton(
                  currentTryonIndex: currentTryonIndex.value,
                  customAvatarIndex: customAvatarIndex.value,
                  onDownload: downloadCurrentMedia,
                  onToggleAvatar: toggleAvatar,
                  onDelete: deleteCurrentTryon,
                ),
              ),

            // 4. Bottom Left — Indicator (white floating lines)
            if (showIndicator)
              Positioned(
                bottom: bottomOffset + AppSpacing.xl,
                left: AppSpacing.xxl,
                child: TryOnIndicator(
                  currentTryonIndex: currentTryonIndex.value,
                  tryonImagesCount: tryonImages.value.length,
                ),
              ),

            // 5. Bottom Right — Try On Button (dark glassmorphism pill)
            avatarAsync.maybeWhen(
              data: (final avatarFile) {
                final hasAvatar = avatarFile != null;
                return Positioned(
                  bottom: bottomOffset + AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: HomePrimaryActionButton(
                    label: hasAvatar ? '虛擬試穿' : '上傳照片',
                    icon: hasAvatar ? Icons.auto_awesome_rounded : Icons.upload_rounded,
                    isDisabled: isUploadingAvatar.value,
                    onTap: hasAvatar ? tryOnFromLocal : uploadAvatar,
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
