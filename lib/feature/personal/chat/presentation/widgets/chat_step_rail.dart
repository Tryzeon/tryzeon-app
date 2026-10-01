import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/tool_step_label.dart';

class ChatStepRail extends HookConsumerWidget {
  const ChatStepRail({super.key, required this.steps, required this.isLive});

  final List<ChatToolStep> steps;
  final bool isLive;

  static const double _markerSize = AppSpacing.smMd;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    final categories = ref.watch(productCategoriesProvider).value ?? const [];
    final categoryNameByCode = {for (final c in categories) c.code: c.name};

    final expanded = useState(false);
    final isExpanded = isLive || expanded.value;
    final foundCount = steps.fold(0, (final n, final step) => n + step.itemCount);

    return AnimatedSize(
      duration: AppDuration.standard,
      curve: AppCurves.enter,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isLive)
            InkWell(
              onTap: () => expanded.value = !expanded.value,
              borderRadius: AppRadius.buttonAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '已搜尋 ${steps.length} 次 · 找到 $foundCount 件',
                        style: textStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    AnimatedRotation(
                      turns: expanded.value ? 0.25 : 0,
                      duration: AppDuration.standard,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: AppSpacing.md,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isExpanded)
            Container(
              margin: EdgeInsets.only(
                top: isLive ? 0 : AppSpacing.xs,
                left: _markerSize / 2,
              ),
              padding: const EdgeInsets.only(left: AppSpacing.smMd),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colorScheme.outline, width: AppStroke.thin),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final step in steps)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: _markerSize,
                            child: step.isRunning
                                ? CircularProgressIndicator(
                                    strokeWidth: AppStroke.thin,
                                    color: colorScheme.onSurfaceVariant,
                                  )
                                : Icon(
                                    Icons.check_rounded,
                                    size: _markerSize,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              toolStepLabel(step.use, categoryNameByCode) +
                                  (step.isRunning ? '' : ' · 找到 ${step.itemCount} 件'),
                              style: textStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
