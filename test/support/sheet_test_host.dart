import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// The result is wrapped in a record because an `async` function returning a
/// bare `Future<T?>` would await it, blocking until the sheet closes.
Future<({Future<T?> result})> openSheet<T>(
  final WidgetTester tester,
  final Future<T?> Function(BuildContext context) show, {
  final List<Override> overrides = const [],
}) async {
  late Future<T?> result;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (final context) => TextButton(
              onPressed: () => result = show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await settle(tester);
  return (result: result);
}

/// Time-boxed rather than `pumpAndSettle`: sheets with a running spinner never
/// settle. Two rounds, because an awaited result can schedule more work
/// post-frame — such as a toast's entry — that only lands a frame later.
Future<void> settle(final WidgetTester tester) async {
  for (var round = 0; round < 2; round++) {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> dismissByDrag(final WidgetTester tester) async {
  final sheetTop = tester.getTopLeft(find.byType(BottomSheet));
  final sheetWidth = tester.getSize(find.byType(BottomSheet)).width;
  await tester.flingFrom(
    sheetTop + Offset(sheetWidth / 2, kMinInteractiveDimension / 2),
    const Offset(0, 600),
    2000,
  );
  await settle(tester);
}
