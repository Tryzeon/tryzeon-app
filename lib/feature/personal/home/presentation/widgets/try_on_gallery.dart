import 'dart:convert';
import 'dart:io';
import 'dart:ui';

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
            return _VideoPlayerItem(videoUrl: result.videoUrl!);
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
  const _VideoPlayerItem({required this.videoUrl});
  final String videoUrl;

  @override
  Widget build(final BuildContext context) {
    final controllerState = useState<VideoPlayerController?>(null);
    final isPlaying = useState<bool>(true);

    useEffect(() {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      controller.initialize().then((_) {
        controllerState.value = controller;
        controller.play(); // 自動播放
        controller.setLooping(true); // 循環播放

        // 監聽播放狀態變化
        void listener() {
          isPlaying.value = controller.value.isPlaying;
        }

        controller.addListener(listener);
      });
      return () {
        controllerState.value?.dispose();
      };
    }, [videoUrl]);

    if (controllerState.value != null && controllerState.value!.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controllerState.value!.value.size.width,
                height: controllerState.value!.value.size.height,
                child: VideoPlayer(controllerState.value!),
              ),
            ),
          ),
          if (!isPlaying.value)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
              ),
            ),
          GestureDetector(
            onTap: () {
              if (controllerState.value!.value.isPlaying) {
                controllerState.value!.pause();
              } else {
                controllerState.value!.play();
              }
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ],
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
