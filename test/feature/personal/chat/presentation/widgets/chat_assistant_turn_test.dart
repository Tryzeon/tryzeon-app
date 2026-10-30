import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/chat/presentation/state/chat_timeline.dart';
import 'package:tryzeon/feature/personal/chat/presentation/widgets/chat_assistant_turn.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';

final _product = ShopProduct(
  id: 'p1',
  storeInfo: const ShopStoreInfo(id: 's1', name: 'Store', channels: {}),
  name: 'Tee',
  categoryId: 'c',
  garmentType: GarmentType.top,
  price: 690,
  colors: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _reply = ChatAssistantEntry(
  status: ChatTurnStatus.done,
  segments: [
    const ChatTextSegment('reply'),
    ChatPicksSegment([
      ResolvedPick(item: ResolvedItem.product(_product, null)),
    ]),
  ],
);

void main() {
  Future<void> pumpTurn(
    final WidgetTester tester,
    final ChatAssistantEntry entry, {
    final Key? key,
  }) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ChatAssistantTurn(
            key: key,
            entry: entry,
            gutter: EdgeInsets.zero,
          ),
        ),
      ),
    ),
  );

  double opacityAbove(final WidgetTester tester, final Finder finder) => tester
      .widget<Opacity>(
        find.ancestor(of: finder, matching: find.byType(Opacity)).first,
      )
      .opacity;

  testWidgets('a reply landing on a pending turn fades its text and cards in', (
    final tester,
  ) async {
    await pumpTurn(
      tester,
      const ChatAssistantEntry(status: ChatTurnStatus.thinking),
    );
    await pumpTurn(tester, _reply);

    expect(opacityAbove(tester, find.text('reply')), lessThan(1));
    expect(opacityAbove(tester, find.text('Tee')), lessThan(1));

    await tester.pumpAndSettle();
    expect(opacityAbove(tester, find.text('reply')), 1);
    expect(opacityAbove(tester, find.text('Tee')), 1);
  });

  testWidgets('a finished turn mounted again (scrolled back) does not replay', (
    final tester,
  ) async {
    await pumpTurn(tester, _reply, key: const ValueKey('remounted'));

    expect(opacityAbove(tester, find.text('reply')), 1);
    expect(opacityAbove(tester, find.text('Tee')), 1);
  });

  testWidgets('an empty answer says it did not understand', (
    final tester,
  ) async {
    await pumpTurn(
      tester,
      const ChatAssistantEntry(
        status: ChatTurnStatus.done,
        segments: [ChatEmptyAnswerSegment()],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('抱歉，我沒有理解，可以再說一次你的需求嗎？'), findsOneWidget);
  });
}
