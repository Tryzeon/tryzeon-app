import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/video_prompt_customize_sheet.dart';

class TryOnModeSheet extends StatelessWidget {
  const TryOnModeSheet({
    super.key,
    required this.hasVideoAccess,
    required this.onModeSelected,
  });

  final bool hasVideoAccess;
  final ValueChanged<TryOnMode> onModeSelected;

  /// Show the bottom sheet. Returns the selected TryOnMode or null if dismissed.
  static Future<void> show({
    required final BuildContext context,
    required final bool hasVideoAccess,
    required final ValueChanged<TryOnMode> onModeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (final context) =>
          TryOnModeSheet(hasVideoAccess: hasVideoAccess, onModeSelected: onModeSelected),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ① Drag Handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ② Title
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 10),
                    Text('選擇試穿方式', style: textTheme.titleLarge),
                  ],
                ),
              ),

              // ③ Image Try-On Card
              _ModeCard(
                icon: Icons.photo_outlined,
                title: '圖片試穿',
                subtitle: '讓 AI 幫你穿上這件衣服',
                isLocked: false,
                isNew: false,
                onTap: () {
                  Navigator.pop(context);
                  onModeSelected(TryOnMode.image);
                },
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),

              const SizedBox(height: 12),

              // ④ Video Try-On Card
              _ModeCard(
                icon: Icons.videocam_outlined,
                title: '影片試穿',
                subtitle: '生成你的走秀影片',
                isLocked: !hasVideoAccess,
                isNew: true,
                onTap: () {
                  Navigator.pop(context);
                  onModeSelected(TryOnMode.video);
                },
                onCustomize: () {
                  VideoPromptCustomizeSheet.show(context);
                },
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLocked,
    required this.isNew,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
    this.onCustomize,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLocked;
  final bool isNew;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback? onCustomize;

  @override
  Widget build(final BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: colorScheme.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: colorScheme.onPrimary, size: 20),
                  ),
                  const SizedBox(width: 14),

                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isLocked)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.lock_rounded,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            Text(title, style: textTheme.titleSmall),
                            if (isNew) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'NEW',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: textTheme.bodySmall),
                      ],
                    ),
                  ),

                  // Customize button (pencil) — only when unlocked and callback provided
                  if (!isLocked && onCustomize != null)
                    GestureDetector(
                      onTap: onCustomize,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  // Chevron (only show when unlocked)
                  if (!isLocked)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),

              // ⑤ Upgrade button (non-Max only)
              if (isLocked) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.personalSubscription);
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('升級至 Max 方案解鎖'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
