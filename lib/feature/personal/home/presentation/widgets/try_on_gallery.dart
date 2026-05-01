import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
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
    required this.currentTryonIndex,
    required this.avatarFile,
    required this.isUploadingAvatar,
  });

  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onUploadTap;
  final List<TryonResult> tryonResults;
  final int currentTryonIndex;
  final File? avatarFile;
  final bool isUploadingAvatar;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canUploadAvatar = currentTryonIndex == -1 && !isUploadingAvatar;

    return GestureDetector(
      onTap: canUploadAvatar ? onUploadTap : null,
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
                return _ImageItem(
                  imageProvider: imageProvider,
                  showLoadingOverlay: isUploadingAvatar,
                );
              }

              final result = tryonResults[index - 1];

              if (result.isLoading) {
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.scrim.withValues(alpha: AppOpacity.strong),
                      colorScheme.scrim.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 1.0],
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      colorScheme.scrim.withValues(alpha: AppOpacity.strong),
                      colorScheme.scrim.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 1.0],
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
      ).animate(CurvedAnimation(parent: animationController, curve: AppCurves.standard)),
    );

    return Container(
      color: colorScheme.onSurface.withValues(alpha: opacity),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          color: colorScheme.surface.withValues(alpha: AppOpacity.strong),
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
    this.showLoadingOverlay = false,
  });

  final String? imageBase64;
  final ImageProvider? imageProvider;
  final bool showLoadingOverlay;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        if (showLoadingOverlay)
          ColoredBox(
            color: colorScheme.scrim.withValues(alpha: AppOpacity.overlay),
            child: Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
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
      return Center(
        child: CircularProgressIndicator(
          color: colorScheme.onPrimary.withValues(alpha: AppOpacity.overlay),
        ),
      );
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
            Icon(
              Icons.play_arrow_rounded,
              color: colorScheme.onPrimary.withValues(alpha: AppOpacity.overlay),
              size: 64,
            ),
        ],
      ),
    );
  }
}
