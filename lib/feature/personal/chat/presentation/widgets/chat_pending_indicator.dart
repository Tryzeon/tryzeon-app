import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatPendingIndicator extends HookWidget {
  const ChatPendingIndicator({super.key, required this.label});

  final String label;

  static const double _dotSize = AppSpacing.xs + AppSpacing.xxs;
  static const double _bounce = AppSpacing.xs;
  static const int _dotCount = 3;
  static const double _phaseStep = 0.15;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final controller = useAnimationController(
      duration: AppDuration.thinking ~/ 2,
    );
    useEffect(() {
      controller.repeat();
      return null;
    }, [controller]);

    return Row(
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (final context, final _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _dotCount; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                _Dot(
                  lift: _lift(controller.value - i * _phaseStep),
                  color: colorScheme.onSurface,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppDuration.standard,
            layoutBuilder: (final current, final previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, ?current],
            ),
            child: Text(
              label,
              key: ValueKey(label),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Each dot rises during the first half of its phase and rests for the rest,
  // so the three read as a travelling wave rather than a synchronized blink.
  static double _lift(final double t) {
    final phase = t % 1;
    return phase < 0.5 ? math.sin(phase * 2 * math.pi) : 0;
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.lift, required this.color});

  final double lift;
  final Color color;

  @override
  Widget build(final BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -ChatPendingIndicator._bounce * lift),
      child: Opacity(
        opacity: AppOpacity.strong + (1 - AppOpacity.strong) * lift,
        child: SizedBox.square(
          dimension: ChatPendingIndicator._dotSize,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
