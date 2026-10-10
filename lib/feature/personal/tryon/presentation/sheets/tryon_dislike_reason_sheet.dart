import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_dislike_reason.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_rating_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/mappers/tryon_dislike_reason_ui_mapper.dart';

/// Resolves with the explanation picked or typed, or null when dismissed.
class TryonDislikeReasonSheet extends HookConsumerWidget {
  const TryonDislikeReasonSheet({super.key, required this.tryonId});

  static const int _maxCommentLength = 200;

  final String tryonId;

  static Future<TryonDislike?> show({
    required final BuildContext context,
    required final String tryonId,
  }) {
    return showAppSheet<TryonDislike>(
      context: context,
      builder: (final _) => TryonDislikeReasonSheet(tryonId: tryonId),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isTyping = useState(false);
    final commentController = useTextEditingController();
    useListenable(commentController);

    final feedbackProvider = tryonRatingControllerProvider.select(
      (final s) => s.feedback[tryonId],
    );
    final route = ModalRoute.of(context);
    void closeUnlessDisliked(final TryonFeedback? feedback) {
      if (feedback is! TryonDislike && (route?.isCurrent ?? false)) {
        Navigator.of(context).pop();
      }
    }

    ref.listen(feedbackProvider, (final _, final next) {
      closeUnlessDisliked(next);
    });
    // A dislike that fails fast is reverted before this sheet first builds,
    // so the listener above never sees it change.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (context.mounted) closeUnlessDisliked(ref.read(feedbackProvider));
      });
      return null;
    }, const []);

    void answer(final TryonDislike explanation) =>
        Navigator.of(context).pop(explanation);

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (isTyping.value) {
      final comment = commentController.text.trim();
      return AppSheet(
        title: '哪裡不滿意？',
        onBack: () => isTyping.value = false,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            controller: commentController,
            autofocus: true,
            maxLength: _maxCommentLength,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(hintText: '告訴我們哪裡不對'),
          ),
        ),
        footer: FilledButton(
          onPressed: comment.isEmpty
              ? null
              : () => answer(TryonDislike(comment: comment)),
          child: const Text('送出'),
        ),
      );
    }

    return AppSheet(
      title: '哪裡不滿意？',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '選填，協助我們改進試穿品質',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final reason in TryonDislikeReason.values)
                  ActionChip(
                    label: Text(reason.label),
                    onPressed: () => answer(TryonDislike(reason: reason)),
                  ),
                ActionChip(
                  label: const Text('其他'),
                  onPressed: () => isTyping.value = true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
