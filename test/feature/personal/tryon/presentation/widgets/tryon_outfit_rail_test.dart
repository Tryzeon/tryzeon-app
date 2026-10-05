import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_outfit_rail.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';

import '../../../../../support/wardrobe_test_doubles.dart';

void main() {
  const product = OutfitPiece.product(
    productId: 'p1',
    name: '亞麻襯衫',
    imageUrl: '',
    garmentType: GarmentType.top,
  );

  Future<void> pumpRail(
    final WidgetTester tester,
    final List<OutfitPiece> pieces, {
    final VoidCallback? onEdit,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (final _, final _) => Scaffold(
            body: ColoredBox(
              color: Colors.black,
              child: TryonOutfitRail(pieces: pieces, onEdit: onEdit ?? () {}),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.personalShopProduct,
          builder: (final _, final state) =>
              Text('product ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: AppRoutes.personalHomePhoto,
          builder: (final _, final state) =>
              Text('photo ${state.uri.queryParameters['path']}'),
        ),
        GoRoute(
          path: AppRoutes.personalWardrobeItem,
          builder: (final _, final state) =>
              Text('wardrobe ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wardrobeItemImageProvider.overrideWith(
            (final ref, final imagePath) => Completer<File>().future,
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows one tile per piece and badges only shop products', (
    final tester,
  ) async {
    await pumpRail(tester, [
      product,
      wardrobePiece('a'),
      const OutfitPiece.local(path: '/tmp/none.jpg'),
    ]);

    expect(find.byKey(const Key('outfit-rail-p1')), findsOneWidget);
    expect(find.byKey(const Key('outfit-rail-a')), findsOneWidget);
    expect(find.byKey(const Key('outfit-rail-/tmp/none.jpg')), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
  });

  testWidgets('a product tile opens its product page', (final tester) async {
    await pumpRail(tester, [product]);

    await tester.tap(find.byKey(const Key('outfit-rail-p1')));
    await tester.pumpAndSettle();

    expect(find.text('product p1'), findsOneWidget);
  });

  testWidgets('a wardrobe tile opens its wardrobe item', (final tester) async {
    await pumpRail(tester, [wardrobePiece('a')]);

    await tester.tap(find.byKey(const Key('outfit-rail-a')));
    await tester.pumpAndSettle();

    expect(find.text('wardrobe a'), findsOneWidget);
  });

  testWidgets('a local photo tile opens its photo page', (final tester) async {
    await pumpRail(tester, [const OutfitPiece.local(path: '/tmp/none.jpg')]);

    await tester.tap(find.byKey(const Key('outfit-rail-/tmp/none.jpg')));
    await tester.pumpAndSettle();

    expect(find.text('photo /tmp/none.jpg'), findsOneWidget);
  });

  testWidgets('only the last tile carries the edit badge', (final tester) async {
    await pumpRail(tester, [product, wardrobePiece('a')]);

    final badge = tester.getCenter(find.byIcon(Icons.edit_outlined));
    final lastTile = tester.getRect(find.byKey(const Key('outfit-rail-a')));

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(badge.dy, greaterThan(lastTile.center.dy));
    expect(badge.dx, greaterThan(lastTile.center.dx));
  });

  testWidgets('the edit badge hands the outfit back for editing', (final tester) async {
    var edits = 0;
    await pumpRail(tester, [product], onEdit: () => edits++);

    await tester.tap(find.byTooltip('編輯搭配'));
    await tester.pumpAndSettle();

    expect(edits, 1);
    expect(find.text('product p1'), findsNothing);
  });
}
