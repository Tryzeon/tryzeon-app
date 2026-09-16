import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_slot.dart';

void main() {
  testWidgets('a leaving slot fades without scaling down', (final tester) async {
    const piece = OutfitPiece.local(path: '/tmp/does-not-exist.png');

    Future<void> pumpSlot(final OutfitPiece? piece) {
      return tester.pumpWidget(
        ProviderScope(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: Theme(
                data: AppTheme.lightTheme,
                child: Material(
                  child: OutfitSlot(
                    index: 0,
                    piece: piece,
                    kind: OutfitSlotKind.filled,
                    onRemove: (final _) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pumpSlot(piece);
    await tester.pump(const Duration(milliseconds: 500));

    await pumpSlot(null);
    await tester.pump(const Duration(milliseconds: 40));

    final removeKey = find.byKey(Key('outfit-slot-remove-${piece.id}'));
    expect(removeKey, findsOneWidget);

    final transform = tester.widget<Transform>(
      find.ancestor(of: removeKey, matching: find.byType(Transform)).first,
    );
    expect(transform.transform.storage[0], 1.0);
  });
}
