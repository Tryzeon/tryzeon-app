import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/actions/tryon_outcome_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';

class _EmittingTryonController extends TryonController {
  @override
  TryonOutcome? build() => null;

  // ignore: use_setters_to_change_properties
  void emit(final TryonOutcome outcome) => state = outcome;
}

class _Listening extends ConsumerWidget {
  const _Listening();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    listenToTryonOutcomes(context, ref);
    return const Scaffold();
  }
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        tryonControllerProvider.overrideWith(_EmittingTryonController.new),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpFeedback(final WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.lightTheme, home: const _Listening()),
    ),
  );

  void emit(final TryonOutcome outcome) =>
      (container.read(tryonControllerProvider.notifier)
              as _EmittingTryonController)
          .emit(outcome);

  testWidgets('a rate-limited run offers the upgrade', (final tester) async {
    await pumpFeedback(tester);

    emit(const TryonRateLimited('r1', isVideo: false));
    await tester.pumpAndSettle();

    expect(find.text('試穿次數已達上限'), findsOneWidget);
  });

  testWidgets('a cancelled run stays silent', (final tester) async {
    await pumpFeedback(tester);

    emit(const TryonCancelled('r1'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
