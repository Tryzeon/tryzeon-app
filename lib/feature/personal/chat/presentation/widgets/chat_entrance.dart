import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatEntrance extends HookWidget {
  const ChatEntrance({
    super.key,
    required this.animate,
    this.delay = Duration.zero,
    required this.child,
  });

  final bool animate;
  final Duration delay;
  final Widget child;

  static const double _rise = AppSpacing.md;

  @override
  Widget build(final BuildContext context) {
    final controller = useAnimationController(
      duration: AppDuration.standard,
      initialValue: animate ? 0 : 1,
    );
    useEffect(() {
      if (controller.isCompleted) return null;
      if (delay == Duration.zero) {
        controller.forward();
        return null;
      }
      var cancelled = false;
      Future.delayed(delay, () {
        if (!cancelled) controller.forward();
      });
      return () => cancelled = true;
    }, [controller]);

    final progress = useMemoized(
      () => CurvedAnimation(parent: controller, curve: AppCurves.enter),
      [controller],
    );

    return AnimatedBuilder(
      animation: progress,
      builder: (final context, final child) => Opacity(
        opacity: progress.value,
        child: Transform.translate(
          offset: Offset(0, _rise * (1 - progress.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
