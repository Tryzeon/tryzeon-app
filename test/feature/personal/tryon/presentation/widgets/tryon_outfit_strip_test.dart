import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/outfit_piece_thumbnail.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_outfit_strip.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

void main() {
  testWidgets('shows one thumbnail per piece and the count', (final tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wardrobeItemImageProvider.overrideWith(
            (final ref, final imagePath) => Completer<File>().future,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ColoredBox(
              color: Colors.black,
              child: TryonOutfitStrip(
                pieces: [wardrobePiece('a'), wardrobePiece('b')],
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(OutfitPieceThumbnail), findsNWidgets(2));
    expect(find.text('2 件'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tryon-outfit-strip')));
    expect(taps, 1);
  });
}
