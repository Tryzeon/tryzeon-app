import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_dislike_reason.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_rating_repository.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_dislike_reason_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_rating_buttons.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/sheet_test_host.dart';

class _FakeRatingRepository implements TryonRatingRepository {
  _FakeRatingRepository({this.failure, this.gate, this.outcomes = const []});

  final Failure? failure;
  final Completer<void>? gate;

  /// Per-call outcomes, used in order before falling back to [failure].
  final List<Failure?> outcomes;
  final sent = <(String, TryonFeedback?)>[];

  @override
  Future<Result<void, Failure>> rate({
    required final String tryonId,
    required final TryonFeedback? feedback,
  }) async {
    final outcome = sent.length < outcomes.length
        ? outcomes[sent.length]
        : failure;
    sent.add((tryonId, feedback));
    await gate?.future;
    if (outcome case final failure?) return Err(failure);
    return const Ok(null);
  }
}

void main() {
  late _FakeRatingRepository repository;

  Future<void> pumpButtons(
    final WidgetTester tester, {
    final Failure? failure,
    final Completer<void>? gate,
    final List<Failure?> outcomes = const [],
  }) async {
    repository = _FakeRatingRepository(
      failure: failure,
      gate: gate,
      outcomes: outcomes,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          tryonRatingRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: TryonRatingButtons(tryonId: 't1')),
        ),
      ),
    );
  }

  Future<void> tapTooltip(final WidgetTester tester, final String tip) async {
    await tester.tap(find.byTooltip(tip));
    await settle(tester);
  }

  testWidgets('starts unrated', (final tester) async {
    await pumpButtons(tester);

    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
  });

  testWidgets('liking marks the like and saves it for this try-on', (
    final tester,
  ) async {
    await pumpButtons(tester);

    await tapTooltip(tester, '喜歡');

    expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
    expect(repository.sent, [('t1', const TryonFeedback.like())]);
  });

  testWidgets('disliking after liking switches the mark', (final tester) async {
    await pumpButtons(tester);

    await tapTooltip(tester, '喜歡');
    await tapTooltip(tester, '不喜歡');

    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
  });

  testWidgets('disliking asks what fell short', (final tester) async {
    await pumpButtons(tester);

    await tapTooltip(tester, '不喜歡');

    expect(find.byType(TryonDislikeReasonSheet), findsOneWidget);
  });

  testWidgets('liking asks nothing', (final tester) async {
    await pumpButtons(tester);

    await tapTooltip(tester, '喜歡');

    expect(find.byType(TryonDislikeReasonSheet), findsNothing);
    expect(find.text('感謝你的回饋'), findsNothing);
  });

  testWidgets('clearing a dislike asks nothing', (final tester) async {
    await pumpButtons(tester);
    await tapTooltip(tester, '不喜歡');
    await dismissByDrag(tester);

    await tapTooltip(tester, '不喜歡');

    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
    expect(find.byType(TryonDislikeReasonSheet), findsNothing);
  });

  testWidgets('a failed save reverts the mark and says so', (
    final tester,
  ) async {
    await pumpButtons(tester, failure: const ServerFailure());

    await tapTooltip(tester, '不喜歡');

    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
    expect(find.byType(TryonDislikeReasonSheet), findsNothing);
    expect(find.text('評分失敗，請稍後再試'), findsOneWidget);

    toastification.dismissAll(delayForAnimation: false);
    await settle(tester);
  });

  testWidgets('a picked reason is saved with the dislike', (
    final tester,
  ) async {
    await pumpButtons(tester);
    await tapTooltip(tester, '不喜歡');

    await tester.tap(find.text('服飾變形'));
    await settle(tester);

    expect(find.byType(TryonDislikeReasonSheet), findsNothing);
    expect(repository.sent.last, (
      't1',
      const TryonFeedback.dislike(reason: TryonDislikeReason.garmentDeformed),
    ));
    expect(find.text('感謝你的回饋'), findsOneWidget);
  });

  testWidgets('a dismissed sheet thanks no one', (final tester) async {
    await pumpButtons(tester);
    await tapTooltip(tester, '不喜歡');

    await dismissByDrag(tester);

    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
    expect(find.text('感謝你的回饋'), findsNothing);
  });

  testWidgets('a reason that fails to save says so', (final tester) async {
    await pumpButtons(tester, outcomes: [null, const ServerFailure()]);
    await tapTooltip(tester, '不喜歡');

    await tester.tap(find.text('臉不像我'));
    await settle(tester);

    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
    expect(find.text('送出原因失敗，請稍後再試'), findsOneWidget);
    expect(find.text('評分失敗，請稍後再試'), findsNothing);
    expect(find.text('感謝你的回饋'), findsNothing);

    toastification.dismissAll(delayForAnimation: false);
    await settle(tester);
  });

  testWidgets('sits on a glass pill rather than bare over the photo', (
    final tester,
  ) async {
    await pumpButtons(tester);

    expect(
      find.descendant(
        of: find.byType(GlassPill),
        matching: find.byIcon(Icons.thumb_up_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byType(IconButton), findsNothing);
  });

  group('haptics', () {
    late List<String> haptics;

    setUp(() {
      haptics = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            final call,
          ) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments as String);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
    });

    testWidgets('a rating tap clicks', (final tester) async {
      await pumpButtons(tester);

      await tapTooltip(tester, '喜歡');

      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('a tap ignored while saving does not click', (
      final tester,
    ) async {
      final gate = Completer<void>();
      await pumpButtons(tester, gate: gate);

      await tapTooltip(tester, '喜歡');
      await tapTooltip(tester, '不喜歡');
      gate.complete();
      await settle(tester);

      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });
  });
}
