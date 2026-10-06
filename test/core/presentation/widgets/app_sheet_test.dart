import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

const _screenSize = Size(390, 844);
const _keyboardHeight = 336.0;
const _footerKey = ValueKey('footer');

void main() {
  void useScreen(final WidgetTester tester, {final double keyboard = 0}) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = _screenSize;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
  }

  Future<void> openSheet(
    final WidgetTester tester,
    final WidgetBuilder builder,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (final context) => TextButton(
              onPressed: () =>
                  showAppSheet<void>(context: context, builder: builder),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Widget longBody() => Column(
    children: [for (var i = 0; i < 40; i++) ListTile(title: Text('item $i'))],
  );

  Widget footer() => FilledButton(
    key: _footerKey,
    onPressed: () {},
    child: const Text('submit'),
  );

  testWidgets('shows the drag handle and a header with icon and trailing', (
    final tester,
  ) async {
    useScreen(tester);
    await openSheet(
      tester,
      (final _) => AppSheet(
        title: '標題',
        icon: Icons.tune_rounded,
        trailing: TextButton(onPressed: () {}, child: const Text('完成')),
        body: const Text('body'),
      ),
    );

    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
    );
    expect(find.text('標題'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
  });

  testWidgets('shows a back button in place of the icon', (final tester) async {
    useScreen(tester);
    var backs = 0;
    await openSheet(
      tester,
      (final _) => AppSheet(
        title: '標題',
        icon: Icons.tune_rounded,
        onBack: () => backs++,
        body: const Text('body'),
      ),
    );

    expect(find.byIcon(Icons.tune_rounded), findsNothing);
    final backButton = find.ancestor(
      of: find.byTooltip('返回'),
      matching: find.byType(IconButton),
    );
    expect(tester.getTopLeft(backButton).dx, AppSpacing.xs);

    await tester.tap(find.byTooltip('返回'));

    expect(backs, 1);
  });

  testWidgets('system back runs onBack instead of closing the sheet', (
    final tester,
  ) async {
    useScreen(tester);
    var backs = 0;
    await openSheet(
      tester,
      (final _) => AppSheet(
        title: '標題',
        onBack: () => backs++,
        body: const Text('body'),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(backs, 1);
    expect(find.byType(AppSheet), findsOneWidget);
  });

  testWidgets('system back closes a sheet without onBack', (
    final tester,
  ) async {
    useScreen(tester);
    await openSheet(
      tester,
      (final _) => const AppSheet(title: '標題', body: Text('body')),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AppSheet), findsNothing);
  });

  testWidgets('content height hugs a short body', (final tester) async {
    useScreen(tester);
    await openSheet(
      tester,
      (final _) => const AppSheet(title: '標題', body: Text('body')),
    );

    expect(
      tester.getSize(find.byType(AppSheet)).height,
      lessThan(_screenSize.height / 3),
    );
  });

  testWidgets('content height scrolls a body taller than the screen', (
    final tester,
  ) async {
    useScreen(tester);
    await openSheet(
      tester,
      (final _) => AppSheet(title: '標題', body: longBody(), footer: footer()),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byKey(_footerKey)).dy,
      lessThanOrEqualTo(_screenSize.height),
    );

    await tester.scrollUntilVisible(find.text('item 39'), 200);
    expect(find.text('item 39'), findsOneWidget);
  });

  testWidgets('tall height fixes the sheet at the tall fraction', (
    final tester,
  ) async {
    useScreen(tester);
    await openSheet(
      tester,
      (final _) => AppSheet(
        title: '標題',
        height: AppSheetHeight.tall,
        body: ListView(children: const [Text('short')]),
      ),
    );

    expect(
      tester.getSize(find.byType(AppSheet)).height,
      moreOrLessEquals(_screenSize.height * AppSheetHeight.tallFraction),
    );
  });

  testWidgets('content footer stays above the keyboard', (final tester) async {
    useScreen(tester, keyboard: _keyboardHeight);
    await openSheet(
      tester,
      (final _) =>
          AppSheet(title: '標題', body: const TextField(), footer: footer()),
    );

    expect(
      tester.getBottomLeft(find.byKey(_footerKey)).dy,
      lessThanOrEqualTo(_screenSize.height - _keyboardHeight),
    );
  });

  testWidgets('tall sheet shrinks to fit above the keyboard', (
    final tester,
  ) async {
    useScreen(tester, keyboard: _screenSize.height / 2);
    await openSheet(
      tester,
      (final _) => AppSheet(
        title: '標題',
        height: AppSheetHeight.tall,
        body: ListView(
          children: [for (var i = 0; i < 40; i++) Text('item $i')],
        ),
        footer: footer(),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byKey(_footerKey)).dy,
      lessThanOrEqualTo(_screenSize.height / 2),
    );
  });
}
