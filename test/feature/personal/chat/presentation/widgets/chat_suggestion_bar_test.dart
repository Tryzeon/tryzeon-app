import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_suggestion_bar.dart';

Future<void> _pump(
  final WidgetTester tester,
  final List<String> suggestions, {
  final ValueChanged<String>? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ChatSuggestionBar(suggestions: suggestions, onTap: onTap ?? (_) {}),
    ),
  ),
);

void main() {
  testWidgets('shows one chip per suggestion, in order', (final tester) async {
    await _pump(tester, ['單品', '整套']);

    final labels = tester
        .widgetList<ActionChip>(find.byType(ActionChip))
        .map((final chip) => (chip.label as Text).data);
    expect(labels, ['單品', '整套']);
  });

  testWidgets('tapping a chip hands back its exact text', (final tester) async {
    final tapped = <String>[];
    await _pump(tester, ['單品', '整套'], onTap: tapped.add);

    await tester.tap(find.text('單品'));

    expect(tapped, ['單品']);
  });

  testWidgets('no suggestions draws no chip and takes no height', (
    final tester,
  ) async {
    await _pump(tester, []);

    expect(find.byType(ActionChip), findsNothing);
    expect(tester.getSize(find.byType(ChatSuggestionBar)).height, 0);
  });
}
