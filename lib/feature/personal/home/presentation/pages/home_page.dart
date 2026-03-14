import 'dart:convert';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gal/gal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/core/utils/image_watermark_helper.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_action_button.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_gallery.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_indicator.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_more_options_button.dart';
import 'package:tryzeon/feature/personal/home/providers/home_providers.dart';
import 'package:tryzeon/feature/personal/main/personal_entry_scope.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/providers/subscription_provider.dart';
import 'package:typed_result/typed_result.dart';

class HomePageController {
  Future<void> Function(String clothesPath, {TryOnMode mode})? tryOnFromStorage;

  void dispose() {
    tryOnFromStorage = null;
  }
}

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final avatarAsync = ref.watch(avatarFileProvider);
    final tryonImages = useState<List<TryonResult>>([]);
    final loadingIndices = useState<Set<int>>({});
    final currentTryonIndex = useState(-1);
    final customAvatarIndex = useState<int?>(null);
    final newAvatarFile = useState<File?>(null);
    final pageController = usePageController(initialPage: 0);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Sync PageController with currentTryonIndex changes (from logic)
    useEffect(() {
      if (pageController.hasClients) {
        final targetPage = currentTryonIndex.value + 1;
        if (pageController.page?.round() != targetPage) {
          pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
      return null;
    }, [currentTryonIndex.value]);

    Future<void> uploadAvatar() async {
      final File? imageFile = await ImagePickerHelper.pickImage(context);
      if (imageFile == null) return;

      // Optimistic update
      newAvatarFile.value = imageFile;

      // Upload
      final profile = await ref.read(userProfileProvider.future);
      if (profile == null) return;

      final result = await ref.read(updateUserProfileUseCaseProvider)(
        original: profile,
        target: profile,
        avatarFile: imageFile,
      );

      if (!context.mounted) return;

      if (result.isSuccess) {
        await Future.wait([
          ref.refresh(userProfileProvider.future),
          ref.refresh(avatarFileProvider.future),
        ]);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
          type: NotificationType.error,
        );
      }

      newAvatarFile.value = null;
    }

    Future<void> performTryOn({
      final String? clothesBase64,
      final String? clothesPath,
      final TryOnMode mode = TryOnMode.photo,
    }) async {
      // 0. Check if avatar is uploaded
      final avatarFile = ref.read(avatarFileProvider).value;
      if (avatarFile == null) {
        TopNotification.show(
          context,
          message: '請先上傳您的照片才能進行虛擬試穿',
          type: NotificationType.warning,
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
      final newIndex = tryonImages.value.length;
      final placeholderResult = TryonResult(mode: mode);
      tryonImages.value = [...tryonImages.value, placeholderResult];
      loadingIndices.value = {...loadingIndices.value, newIndex};
      currentTryonIndex.value = newIndex;

      // 3. API Call
      final tryonUseCase = ref.read(tryonUseCaseProvider);
      final result = await tryonUseCase(
        customAvatarBase64: customAvatarBase64,
        clothesBase64: clothesBase64,
        clothesPath: clothesPath,
        mode: mode,
      );

      if (!context.mounted) return;

      // 4. Handle Result
      if (result.isSuccess) {
        final tryonResult = result.get()!;
        tryonImages.value = [...tryonImages.value]..[newIndex] = tryonResult;
        loadingIndices.value = {...loadingIndices.value}..remove(newIndex);

        TopNotification.show(
          context,
          message: mode == TryOnMode.video ? '影片生成成功！' : '試穿成功！',
          type: NotificationType.success,
        );
      } else {
        // Failure: Remove placeholder
        tryonImages.value = [...tryonImages.value]..removeAt(newIndex);
        loadingIndices.value = {...loadingIndices.value}..remove(newIndex);
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
            type: NotificationType.error,
          );
        }
      }
    }

    Future<void> tryOnFromLocal() async {
      final File? clothesImage = await ImagePickerHelper.pickImage(context);
      if (clothesImage == null) return;

      final clothesBytes = await clothesImage.readAsBytes();
      final clothesBase64 = base64Encode(clothesBytes);
      performTryOn(clothesBase64: clothesBase64, mode: TryOnMode.photo);
    }

    Future<void> tryOnFromStorage(
      final String clothesPath, {
      final TryOnMode mode = TryOnMode.photo,
    }) async {
      performTryOn(clothesPath: clothesPath, mode: mode);
    }

    Future<void> downloadCurrentImage() async {
      try {
        final result = tryonImages.value[currentTryonIndex.value];

        final base64String = result.imageBase64!;
        final originalBytes = base64Decode(base64String);

        Uint8List imageToSave = originalBytes;

        final subscription = await ref.read(subscriptionProvider.future);
        if (subscription.requiresWatermark) {
          imageToSave = await ImageWatermarkHelper.addWatermark(originalBytes);
        }

        await Gal.putImageBytes(
          imageToSave,
          name: 'tryzeon_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (context.mounted) {
          TopNotification.show(
            context,
            message: '照片已儲存到相簿',
            type: NotificationType.success,
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to save photo', e, stackTrace);
        if (context.mounted) {
          TopNotification.show(
            context,
            message: '儲存失敗，請檢查儲存權限',
            type: NotificationType.error,
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

      if (context.mounted) {
        TopNotification.show(
          context,
          message: isCurrentlySet ? '已取消試穿形象' : '已設定為試穿形象',
          type: NotificationType.success,
        );
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

        if (context.mounted) {
          TopNotification.show(
            context,
            message: '已刪除試穿照片',
            type: NotificationType.success,
          );
        }
      }
    }

    final activeController = PersonalEntryScope.of(context)?.homePageController;
    useEffect(() {
      if (activeController != null) {
        activeController.tryOnFromStorage = tryOnFromStorage;
        return () => activeController.tryOnFromStorage = null;
      }
      return null;
    }, [activeController]);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () => refreshUserProfile(ref),
        edgeOffset: MediaQuery.of(context).padding.top,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image Layer - wrapped in scrollable for RefreshIndicator
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
                      message: (error as Failure).displayMessage(context),
                      onRetry: () => ref.refresh(userProfileProvider),
                    ),
                  ),
                  data: (final avatarFile) => TryOnGallery(
                    pageController: pageController,
                    onPageChanged: (final index) => currentTryonIndex.value = index - 1,
                    onUploadTap: uploadAvatar,
                    tryonResults: tryonImages.value,
                    loadingIndices: loadingIndices.value,
                    currentTryonIndex: currentTryonIndex.value,
                    avatarFile: newAvatarFile.value ?? avatarFile,
                  ),
                ),
              ),
            ),

            // 2. Top Left Title Layer (Tryzeon)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text(
                    'Tryzeon',
                    style: textTheme.displayLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Top Right Controls
            if (currentTryonIndex.value >= 0 &&
                !loadingIndices.value.contains(currentTryonIndex.value))
              TryOnMoreOptionsButton(
                currentTryonIndex: currentTryonIndex.value,
                customAvatarIndex: customAvatarIndex.value,
                onDownload: downloadCurrentImage,
                onToggleAvatar: toggleAvatar,
                onDelete: deleteCurrentTryon,
              ),

            // 4. Bottom Layer (Navigation & Action) - Aware of Floating Nav Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Navigation Buttons (Left/Center aligned or just floating)
                  if (tryonImages.value.isNotEmpty)
                    TryOnIndicator(
                      currentTryonIndex: currentTryonIndex.value,
                      tryonImagesCount: tryonImages.value.length,
                    ),

                  // Spacing for where the actual bottom bar would be
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 80,
                  ), // Approx floating bar height
                ],
              ),
            ),

            // 5. Try On Button
            Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom +
                  30 +
                  (PlatformInfo.isIOS26OrHigher() ? 50 : 0),
              right: 20,
              child: TryOnActionButton(
                onTap: tryOnFromLocal,
                isDisabled: avatarAsync.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
