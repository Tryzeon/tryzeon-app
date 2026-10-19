import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/chat/domain/failures/chat_rate_limited_failure.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_failure_card.dart';

void main() {
  testWidgets('rate-limit card shows fair-use copy and no action', (
    final tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatFailureCard(
            failure: const ChatRateLimitedFailure(),
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('今天聊得比較多了，休息一下再來找我'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.textContaining('升級'), findsNothing);
  });
}
