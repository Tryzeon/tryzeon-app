import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class NavRow extends StatelessWidget {
  const NavRow({
    required this.title,
    this.icon,
    this.trailingValue,
    this.showChevron = true,
    this.onTap,
    this.isDestructive = false,
    this.isFirst = false,
    super.key,
  });

  final IconData? icon;
  final String title;
  final String? trailingValue;
  final bool showChevron;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isFirst;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final foreground = isDestructive ? colorScheme.error : colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final hairline = BorderSide(color: colorScheme.outline, width: 1);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: isFirst ? hairline : BorderSide.none, bottom: hairline),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            if (icon != null) ...[
              SizedBox(
                width: AppSpacing.lg,
                child: Icon(icon, size: AppSpacing.mdLg, color: foreground),
              ),
              const SizedBox(width: AppSpacing.smMd),
            ],
            Expanded(
              child: Text(title, style: textTheme.bodyLarge?.copyWith(color: foreground)),
            ),
            if (trailingValue != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Text(
                    trailingValue!,
                    style: textTheme.bodyMedium?.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded, size: 18, color: muted),
            ],
          ],
        ),
      ),
    );
  }
}
