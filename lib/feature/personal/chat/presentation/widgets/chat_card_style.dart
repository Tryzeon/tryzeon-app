import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

abstract final class ChatCardStyle {
  static const Color cutoutBackdrop = Color(0xFFEBE7E0);
  static const BorderRadius radius = BorderRadius.all(
    Radius.circular(AppRadius.dialog),
  );
  static const double tagStrokeAlpha = 0.12;
  static const double mutedTextAlpha = 0.8;
  static const double scrimAlpha = 0.5;
  static const double pickAspectRatio = 15 / 22;
}
