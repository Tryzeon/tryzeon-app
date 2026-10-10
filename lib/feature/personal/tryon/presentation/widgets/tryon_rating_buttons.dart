import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/app_snack_bar.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_rating_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_dislike_reason_sheet.dart';

class TryonRatingButtons extends ConsumerWidget {
  const TryonRatingButtons({super.key, required this.tryonId});

  /// Matches the outfit rail's tiles so the two stack as one column.
  static const double _width = 52;
  static const double _iconSize = 22;

  final String tryonId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final feedback = ref.watch(
      tryonRatingControllerProvider.select((final s) => s.feedback[tryonId]),
    );
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> askWhy() async {
      final explanation = await TryonDislikeReasonSheet.show(
        context: context,
        tryonId: tryonId,
      );
      if (explanation == null) return;
      final result = await ref
          .read(tryonRatingControllerProvider.notifier)
          .explain(tryonId, explanation);
      if (!context.mounted) return;
      if (result.isFailure) {
        TopNotification.show(context, message: '送出原因失敗，請稍後再試');
      } else {
        AppSnackBar.show(context, message: '感謝你的回饋');
      }
    }

    Future<void> toggle(final TryonFeedback tapped) async {
      final controller = ref.read(tryonRatingControllerProvider.notifier);
      if (ref.read(tryonRatingControllerProvider).saving.contains(tryonId)) {
        return;
      }
      HapticFeedback.selectionClick();

      final saving = controller.toggle(tryonId, tapped);
      if (tapped is TryonDislike && feedback is! TryonDislike) {
        unawaited(askWhy());
      }
      final result = await saving;
      if (!context.mounted) return;
      if (result.isFailure) {
        TopNotification.show(context, message: '評分失敗，請稍後再試');
      }
    }

    Widget target({
      required final String tooltip,
      required final IconData icon,
      required final TryonFeedback value,
    }) {
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => toggle(value),
          child: SizedBox(
            width: _width,
            height: kMinInteractiveDimension,
            child: Icon(icon, size: _iconSize, color: colorScheme.onPrimary),
          ),
        ),
      );
    }

    return GlassPill(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          target(
            tooltip: '喜歡',
            icon: feedback is TryonLike
                ? Icons.thumb_up
                : Icons.thumb_up_outlined,
            value: const TryonFeedback.like(),
          ),
          SizedBox(
            width: _width - AppSpacing.md,
            height: AppStroke.thin,
            child: ColoredBox(
              color: colorScheme.onPrimary.withValues(alpha: AppOpacity.medium),
            ),
          ),
          target(
            tooltip: '不喜歡',
            icon: feedback is TryonDislike
                ? Icons.thumb_down
                : Icons.thumb_down_outlined,
            value: const TryonFeedback.dislike(),
          ),
        ],
      ),
    );
  }
}
