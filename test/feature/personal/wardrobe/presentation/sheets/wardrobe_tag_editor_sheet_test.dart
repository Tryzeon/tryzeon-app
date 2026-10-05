import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/sheets/wardrobe_tag_editor_sheet.dart';

import '../../../../../support/sheet_test_host.dart';

void main() {
  Future<List<List<String>>> open(
    final WidgetTester tester, {
    final String? saveError,
  }) async {
    final saves = <List<String>>[];
    await openSheet<void>(
      tester,
      (final context) => WardrobeTagEditorSheet.show(
        context: context,
        initialTags: const ['casual'],
        onSave: (final tags) async {
          saves.add(tags);
          return saveError;
        },
      ),
    );
    return saves;
  }

  Future<void> addTag(final WidgetTester tester, final String tag) async {
    await tester.enterText(find.byType(TextField), tag);
    await tester.pump();
    await tester.tap(find.byTooltip('新增標籤'));
    await tester.pumpAndSettle();
  }

  Finder saveButton() => find.widgetWithText(FilledButton, '儲存');

  testWidgets('focuses the tag field on open', (final tester) async {
    await open(tester);

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('shows tags as typed rather than upper-cased', (
    final tester,
  ) async {
    await open(tester);

    await addTag(tester, 'Denim');

    expect(find.text('#Denim'), findsOneWidget);
  });

  testWidgets('disables saving until something changes', (final tester) async {
    await open(tester);

    expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

    await addTag(tester, 'denim');

    expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
  });

  testWidgets('offers save as the only action', (final tester) async {
    await open(tester);

    expect(find.byType(OutlinedButton), findsNothing);
    expect(
      tester.getSize(saveButton()).width,
      tester.getSize(find.byType(TextField)).width,
    );
  });

  testWidgets('saves and closes on save', (final tester) async {
    final saves = await open(tester);

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(find.byType(WardrobeTagEditorSheet), findsNothing);
    expect(saves, [<String>[]]);
  });

  testWidgets('includes text still in the field when saving', (
    final tester,
  ) async {
    final saves = await open(tester);

    await tester.enterText(find.byType(TextField), 'denim');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(saves, [
      ['casual', 'denim'],
    ]);
  });

  testWidgets('stays open with the edits when saving fails', (
    final tester,
  ) async {
    await open(tester, saveError: '儲存失敗');

    await addTag(tester, 'denim');
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(find.byType(WardrobeTagEditorSheet), findsOneWidget);
    expect(find.text('#denim'), findsOneWidget);

    toastification.dismissAll(delayForAnimation: false);
    await tester.pumpAndSettle();
  });

  testWidgets('discards edits when dismissed by drag', (final tester) async {
    final saves = await open(tester);

    await addTag(tester, 'denim');
    await dismissByDrag(tester);

    expect(find.byType(WardrobeTagEditorSheet), findsNothing);
    expect(saves, isEmpty);
  });
}
