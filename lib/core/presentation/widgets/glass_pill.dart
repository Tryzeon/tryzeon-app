import 'package:flutter/material.dart';
import 'package:tryzeon/core/presentation/widgets/glass_surface.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) => GlassSurface(
    borderRadius: AppRadius.pillAll,
    padding: padding,
    child: child,
  );
}
