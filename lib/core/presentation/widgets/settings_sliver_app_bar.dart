import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A SliverAppBar specifically designed for settings pages.
///
/// Features:
/// - Floating and pinned behavior for scrollable content
/// - Rounded back button with theme-based styling
/// - Centered title with consistent typography
/// - Optional custom back button handler
class SettingsSliverAppBar extends StatelessWidget {
  const SettingsSliverAppBar({required this.title, super.key, this.onBackPressed});

  final String title;
  final VoidCallback? onBackPressed;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colorScheme.primary, size: 20),
          onPressed: onBackPressed ?? context.pop,
          padding: EdgeInsets.zero,
        ),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      centerTitle: true,
    );
  }
}
