import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/refresh_feedback_extension.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:typed_result/typed_result.dart';

Future<void> _pumpAndPull(
  final WidgetTester tester,
  final List<Result<void, Failure>> results,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (final context) => RefreshIndicator(
            onRefresh: () => [
              for (final result in results) Future.value(result),
            ].showFirstFailure(context),
            child: ListView(children: const [SizedBox(height: 800)]),
          ),
        ),
      ),
    ),
  );
  await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  await tester.pump(AppDuration.slow);
}

Future<void> _drainToasts(final WidgetTester tester) async {
  toastification.dismissAll(delayForAnimation: false);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('stays silent when every source refreshed', (final tester) async {
    await _pumpAndPull(tester, const [Ok(null), Ok(null)]);

    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    await _drainToasts(tester);
  });

  testWidgets('reports only the first failure', (final tester) async {
    await _pumpAndPull(tester, const [
      Ok(null),
      Err(NetworkFailure('first')),
      Err(ServerFailure('second')),
    ]);

    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsNothing);
    await _drainToasts(tester);
  });
}
