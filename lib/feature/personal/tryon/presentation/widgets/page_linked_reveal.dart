import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Tracks the finger rather than snapping when the page settles; the mount
/// entrance covers appearances no swipe drives, such as the first avatar.
class PageLinkedReveal extends HookWidget {
  const PageLinkedReveal({
    super.key,
    required this.controller,
    required this.interval,
    this.showOnAvatarPage = false,
    required this.child,
  });

  final PageController controller;

  /// Slice of the avatar→first-result swipe, 0 to 1, over which [child] fades.
  final Interval interval;

  final bool showOnAvatarPage;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final entrance = useAnimationController(
      duration: reduceMotion ? Duration.zero : AppDuration.standard,
    );
    useEffect(() {
      entrance.forward();
      return null;
    }, const []);

    return AnimatedBuilder(
      animation: Listenable.merge([controller, entrance]),
      child: child,
      builder: (final context, final child) {
        final page = controller.hasClients && controller.position.hasContentDimensions
            ? controller.page!
            : controller.initialPage.toDouble();
        final progress = interval.transform(page.clamp(0, 1));
        final visibility =
            (showOnAvatarPage ? 1 - progress : progress) *
            AppCurves.enter.transform(entrance.value);

        return IgnorePointer(
          ignoring: visibility < 1,
          child: Opacity(
            opacity: visibility,
            child: Transform.translate(
              offset: Offset(0, reduceMotion ? 0 : (1 - visibility) * AppSpacing.smMd),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
