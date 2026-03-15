import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AdBanner extends HookConsumerWidget {
  const AdBanner({super.key, required this.adsAsync});
  final AsyncValue<List<String>> adsAsync;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageController = usePageController();

    // Priority 1: Show data if available (even during loading or error)
    if (adsAsync.hasValue) {
      final adImages = adsAsync.value!;

      // Handle empty state
      if (adImages.isEmpty) {
        return const SizedBox.shrink();
      }

      useEffect(() {
        if (adImages.isEmpty) return null;

        final timer = Timer.periodic(const Duration(seconds: 3), (final timer) {
          if (!pageController.hasClients) return;

          // Compute next page without triggering a rebuild via State
          final nextPage = (pageController.page?.round() ?? 0) + 1;
          final targetPage = nextPage >= adImages.length ? 0 : nextPage;

          pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
        return timer.cancel;
      }, [adImages]);

      return SizedBox(
        height: 180,
        child: PageView.builder(
          controller: pageController,
          itemCount: adImages.length,
          itemBuilder: (final context, final index) {
            return GestureDetector(
              onTap: () {
                // TODO: 點擊廣告導向詳情頁或外部連結
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(adImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Priority 2: Show skeleton when loading without data
    if (adsAsync.isLoading) {
      return Skeletonizer(
        enabled: true,
        child: Skeleton.leaf(
          child: Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainer,
            ),
          ),
        ),
      );
    }

    // Priority 3: Error without data - silently hide banner
    return const SizedBox.shrink();
  }
}
