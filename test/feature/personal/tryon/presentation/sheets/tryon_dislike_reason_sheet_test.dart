import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_dislike_reason.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_rating_repository.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_rating_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_dislike_reason_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

class _FakeRatingRepository implements TryonRatingRepository {
  @override
  Future<Result<void, Failure>> rate({
    required final String tryonId,
    required final TryonFeedback? feedback,
  }) async => const Ok(null);
}

void main() {
  Future<Future<TryonDislike?>> openOnDislike(final WidgetTester tester) async {
    final opened = await openSheet<TryonDislike>(
      tester,
      (final context) {
        ProviderScope.containerOf(context)
            .read(tryonRatingControllerProvider.notifier)
            .toggle('t1', const TryonFeedback.dislike());
        return TryonDislikeReasonSheet.show(context: context, tryonId: 't1');
      },
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        tryonRatingRepositoryProvider.overrideWithValue(
          _FakeRatingRepository(),
        ),
      ],
    );
    return opened.result;
  }

  Future<void> tapText(final WidgetTester tester, final String text) async {
    await tester.tap(find.text(text));
    await settle(tester);
  }

  testWidgets('asks what fell short, as an optional question', (
    final tester,
  ) async {
    await openOnDislike(tester);

    expect(find.text('哪裡不滿意？'), findsOneWidget);
    expect(find.text('選填，協助我們改進試穿品質'), findsOneWidget);
  });

  testWidgets('offers every reason, then 其他', (final tester) async {
    await openOnDislike(tester);

    expect(
      find.byType(ActionChip),
      findsNWidgets(TryonDislikeReason.values.length + 1),
    );
    expect(find.text('其他'), findsOneWidget);
  });

  testWidgets('picking a reason closes the sheet with it', (
    final tester,
  ) async {
    final result = await openOnDislike(tester);

    await tapText(tester, '臉不像我');

    expect(find.byType(TryonDislikeReasonSheet), findsNothing);
    expect(
      await result,
      const TryonFeedback.dislike(reason: TryonDislikeReason.identityMismatch),
    );
  });

  testWidgets('其他 lets the user type it and send it', (final tester) async {
    final result = await openOnDislike(tester);

    await tapText(tester, '其他');
    await tester.enterText(find.byType(TextField), '  袖子不見了 ');
    await tester.pump();
    await tapText(tester, '送出');

    expect(find.byType(TryonDislikeReasonSheet), findsNothing);
    expect(await result, const TryonFeedback.dislike(comment: '袖子不見了'));
  });

  testWidgets('nothing typed, nothing to send', (final tester) async {
    await openOnDislike(tester);

    await tapText(tester, '其他');
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '送出'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('typing goes back to the reasons', (final tester) async {
    await openOnDislike(tester);
    await tapText(tester, '其他');

    await tester.tap(find.byTooltip('返回'));
    await settle(tester);

    expect(find.text('臉不像我'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('dismissing it explains nothing', (final tester) async {
    final result = await openOnDislike(tester);

    await dismissByDrag(tester);

    expect(await result, isNull);
  });

  testWidgets('closes once the try-on is no longer disliked', (
    final tester,
  ) async {
    final result = await openOnDislike(tester);

    ProviderScope.containerOf(
          tester.element(find.byType(TryonDislikeReasonSheet)),
        )
        .read(tryonRatingControllerProvider.notifier)
        .toggle('t1', const TryonFeedback.like());
    await settle(tester);

    expect(find.byType(TryonDislikeReasonSheet), findsNothing);
    expect(await result, isNull);
  });
}
