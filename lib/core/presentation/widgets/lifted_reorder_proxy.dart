import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

const _liftedScale = 1.03;

Widget liftedReorderProxy(
  final Widget child,
  final int index,
  final Animation<double> animation,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (final context, final child) => Transform.scale(
      scale: lerpDouble(
        1,
        _liftedScale,
        AppCurves.emphasized.transform(animation.value),
      ),
      child: child,
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}
