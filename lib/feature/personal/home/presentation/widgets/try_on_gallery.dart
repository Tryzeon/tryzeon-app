import 'dart:convert';
import 'dart:io';

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
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
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
                return const _SkeletonItem();
              }

              if (result.mode == TryOnMode.video) {
                return _VideoPlayerItem(videoUrl: result.videoUrl!);
              }

              if (result.mode == TryOnMode.image) {
                return _ImageItem(imageBase64: result.imageBase64);
              }

              return const Center(child: Text('Invalid TryOn Result'));
            },
          ),
          // Top Dark Gradient — ensures white logo/icons are legible
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 200,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black26, Colors.transparent],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Bottom Dark Gradient — ensures white indicator/button are legible
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 250,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black38, Colors.transparent],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonItem extends HookWidget {
  const _SkeletonItem();

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    useEffect(() {
      animationController.repeat(reverse: true);
      return null;
    }, const []);

    final opacity = useAnimation(
      Tween<double>(
        begin: 0.6,
        end: 0.85,
      ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOut)),
    );

    return Container(
      color: colorScheme.onSurface.withValues(alpha: opacity),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          color: colorScheme.surface.withValues(alpha: 0.3),
          size: 48,
        ),
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
    final textTheme = Theme.of(context).textTheme;

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

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: finalImageProvider, fit: BoxFit.cover),
      ),
      child: showUploadOverlay
          ? Container(
              color: Colors.black.withValues(alpha: 0.32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.upload_rounded,
                        size: 30,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'UPLOAD PHOTO',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _VideoPlayerItem extends HookWidget {
  const _VideoPlayerItem({required this.videoUrl});
  final String videoUrl;

  Widget _buildVideoFill(final VideoPlayerController controller) {
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final screenHeight = constraints.maxHeight;
        final scaledWidth = screenHeight * controller.value.aspectRatio;
        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: screenHeight,
            child: SizedBox(
              width: scaledWidth,
              height: screenHeight,
              child: VideoPlayer(controller),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final controller = useMemoized(
      () => VideoPlayerController.networkUrl(Uri.parse(videoUrl)),
      [videoUrl],
    );
    final isInitialized = useState(false);
    final showPlayIcon = useState(false);

    useEffect(() {
      controller.initialize().then((_) {
        isInitialized.value = true;
        controller.setLooping(true);
        controller.play();
      });
      return controller.dispose;
    }, [controller]);

    if (!isInitialized.value) {
      return const Center(child: CircularProgressIndicator(color: Colors.white54));
    }

    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
          showPlayIcon.value = true;
        } else {
          controller.play();
          showPlayIcon.value = false;
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildVideoFill(controller),
          if (showPlayIcon.value)
            const Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 64),
        ],
      ),
    );
  }
}
