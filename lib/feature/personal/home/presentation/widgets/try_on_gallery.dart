import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:video_player/video_player.dart';

class TryOnGallery extends HookWidget {
  const TryOnGallery({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.onUploadTap,
    required this.tryonResults,
    required this.loadingIndices,
    required this.currentTryonIndex,
    required this.avatarFile,
  });

  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onUploadTap;
  final List<TryonResult> tryonResults;
  final Set<int> loadingIndices;
  final int currentTryonIndex;
  final File? avatarFile;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: currentTryonIndex == -1 ? onUploadTap : null,
      child: PageView.builder(
        controller: pageController,
        onPageChanged: onPageChanged,
        itemCount: tryonResults.length + 1,
        itemBuilder: (final context, final index) {
          if (index == 0) {
            // Original Avatar
            final ImageProvider imageProvider = avatarFile != null
                ? FileImage(avatarFile!)
                : const AssetImage(AppConstants.defaultProfileImage);
            final showUploadOverlay = avatarFile == null;
            return _ImageItem(
              imageProvider: imageProvider,
              showUploadOverlay: showUploadOverlay,
            );
          }

          final result = tryonResults[index - 1];
          final isLoading = loadingIndices.contains(index - 1);

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (result.mode == TryOnMode.video) {
            return _VideoPlayerItem(videoPath: result.videoPath!);
          }

          if (result.mode == TryOnMode.photo) {
            return _ImageItem(imageBase64: result.imageBase64);
          }

          return const Center(child: Text('Invalid TryOn Result'));
        },
      ),
    );
  }
}

class _ImageItem extends HookWidget {
  const _ImageItem({
    this.imageBase64,
    this.imageProvider,
    this.showUploadOverlay = false,
  });

  final String? imageBase64;
  final ImageProvider? imageProvider;
  final bool showUploadOverlay;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final finalImageProvider = useMemoized(() {
      if (imageProvider != null) {
        return imageProvider!;
      }
      if (imageBase64 != null) {
        final imageBytes = base64Decode(imageBase64!);
        return MemoryImage(imageBytes);
      }
      throw Exception('Either imageBase64 or imageProvider must be provided');
    }, [imageBase64, imageProvider]);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image(image: finalImageProvider, fit: BoxFit.cover, gaplessPlayback: true),
        if (showUploadOverlay)
          Align(
            alignment: const Alignment(0, 0.5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: colorScheme.surface.withValues(alpha: 0.3),
                  child: Text(
                    '點擊上傳照片',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoPlayerItem extends HookWidget {
  const _VideoPlayerItem({required this.videoPath});
  final String videoPath;

  @override
  Widget build(final BuildContext context) {
    final controllerState = useState<VideoPlayerController?>(null);
    final chewieState = useState<ChewieController?>(null);

    useEffect(() {
      final controller = VideoPlayerController.file(File(videoPath));
      controller.initialize().then((_) {
        controllerState.value = controller;
        chewieState.value = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: true,
          aspectRatio: controller.value.aspectRatio,
          showControls: true,
        );
      });
      return () {
        chewieState.value?.dispose();
        controller.dispose();
      };
    }, [videoPath]);

    if (chewieState.value != null && controllerState.value != null) {
      final bottomPadding =
          MediaQuery.of(context).padding.bottom +
          (PlatformInfo.isIOS26OrHigher() ? 10 : 0);

      return Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SafeArea(child: Chewie(controller: chewieState.value!)),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
