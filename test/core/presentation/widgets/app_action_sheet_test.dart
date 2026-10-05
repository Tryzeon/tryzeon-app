import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/presentation/widgets/app_action_sheet.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

void main() {
  Future<void> openSheet(
    final WidgetTester tester, {
    required final List<AppMenuAction> actions,
    final String? title,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (final context) => TextButton(
              onPressed: () =>
                  showAppActionSheet(context, actions: actions, title: title),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  AppMenuAction action(
    final String title, {
    final bool isDestructive = false,
    final VoidCallback? onTap,
  }) => AppMenuAction(
    icon: Icons.circle_outlined,
    title: title,
    onTap: onTap ?? () {},
    isDestructive: isDestructive,
  );

  testWidgets('separates destructive actions from the ones before them', (
    final tester,
  ) async {
    await openSheet(
      tester,
      actions: [
        action('分享'),
        action('重新生成'),
        action('刪除', isDestructive: true),
      ],
    );

    expect(find.byType(Divider), findsOneWidget);
    expect(
      tester.getCenter(find.byType(Divider)).dy,
      allOf(
        greaterThan(tester.getCenter(find.text('重新生成')).dy),
        lessThan(tester.getCenter(find.text('刪除')).dy),
      ),
    );
  });

  testWidgets('adds no divider when nothing precedes the destructive action', (
    final tester,
  ) async {
    await openSheet(tester, actions: [action('取消生成', isDestructive: true)]);

    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('adds no divider when no action is destructive', (
    final tester,
  ) async {
    await openSheet(tester, actions: [action('從相簿選擇'), action('拍攝新照片')]);

    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('shows the title when given', (final tester) async {
    await openSheet(tester, title: '聯絡我們', actions: [action('LINE')]);

    expect(find.text('聯絡我們'), findsOneWidget);
  });

  testWidgets('closes the sheet before running the tapped action', (
    final tester,
  ) async {
    var wasSheetOpenOnTap = true;
    late BuildContext sheetContext;
    await openSheet(
      tester,
      actions: [
        action(
          '分享',
          onTap: () => wasSheetOpenOnTap =
              ModalRoute.of(sheetContext)?.isCurrent ?? false,
        ),
      ],
    );
    sheetContext = tester.element(find.text('分享'));

    await tester.tap(find.text('分享'));
    await tester.pumpAndSettle();

    expect(wasSheetOpenOnTap, isFalse);
    expect(find.text('分享'), findsNothing);
  });
}
