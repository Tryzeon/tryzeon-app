import 'package:flutter/material.dart';

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.color,
    this.isDestructive = false,
    this.hideChevron = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;
  final bool isDestructive;
  final bool hideChevron;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contentColor = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (color ?? colorScheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? colorScheme.error
                      : (color ?? colorScheme.primary),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(color: contentColor),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (!hideChevron)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.outlineVariant,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
