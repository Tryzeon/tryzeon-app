import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_rating.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_rating_controller.dart';

class TryonRatingButtons extends ConsumerWidget {
  const TryonRatingButtons({super.key, required this.tryonId});

  /// Matches the outfit rail's tiles so the two stack as one column.
  static const double _width = 52;
  static const double _iconSize = 22;

  final String tryonId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final rating = ref.watch(
      tryonRatingControllerProvider.select((final s) => s.ratings[tryonId]),
    );
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> toggle(final TryonRating tapped) async {
      final controller = ref.read(tryonRatingControllerProvider.notifier);
      if (ref.read(tryonRatingControllerProvider).saving.contains(tryonId)) {
        return;
      }
      HapticFeedback.selectionClick();

      final result = await controller.toggle(tryonId, tapped);
      if (!context.mounted) return;
      if (result.isFailure) {
        TopNotification.show(context, message: '評分失敗，請稍後再試');
      }
    }

    Widget target({
      required final String tooltip,
      required final IconData icon,
      required final TryonRating value,
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
            icon: rating == TryonRating.like
                ? Icons.thumb_up
                : Icons.thumb_up_outlined,
            value: TryonRating.like,
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
            icon: rating == TryonRating.dislike
                ? Icons.thumb_down
                : Icons.thumb_down_outlined,
            value: TryonRating.dislike,
          ),
        ],
      ),
    );
  }
}
