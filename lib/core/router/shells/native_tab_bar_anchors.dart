import 'package:flutter/widgets.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';

class NativeTabBarAnchors extends StatelessWidget {
  const NativeTabBarAnchors({super.key, required this.anchors});

  // Mirror the iOS 26 native tab bar drawn by adaptive_platform_ui, measured
  // on an iPhone 17 (402x874pt). Flutter cannot see inside that bar, so
  // re-measure these whenever adaptive_platform_ui or iOS changes its layout.
  static const _barSideMargin = 21.0;
  static const _barInnerPadding = 8.0;
  static const _barBottom = 22.0;
  static const _barHeight = 61.0;

  final List<CoachMarkTarget?> anchors;

  @override
  Widget build(final BuildContext context) => IgnorePointer(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _barSideMargin + _barInnerPadding,
          0,
          _barSideMargin + _barInnerPadding,
          _barBottom,
        ),
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: [
              for (final anchor in anchors)
                Expanded(
                  child: switch (anchor) {
                    final target? => CoachMarkAnchor(
                      target: target,
                      child: const SizedBox.expand(),
                    ),
                    null => const SizedBox.shrink(),
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
