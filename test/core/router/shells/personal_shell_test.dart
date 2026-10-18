import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_hint.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/shells/personal_shell.dart';
import 'package:tryzeon/core/router/shells/personal_tab.dart';
import 'package:tryzeon/core/router/shells/personal_tab_navigator.dart';
import 'package:tryzeon/core/router/shells/tab_reselect.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/complete_tutorial.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/controllers/tutorial_controller.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/state/tutorial_state.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/widgets/tutorial_overlay.dart';
import 'package:tryzeon/feature/personal/wardrobe/providers/wardrobe_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../support/wardrobe_test_doubles.dart';

const _dock = Key('outfit-dock');

class _InactiveTutorial extends TutorialController {
  @override
  TutorialState build() => const TutorialState.inactive();
}

class _EmptyGallery extends TryonGalleryNotifier {
  @override
  TryonGalleryState build() => const TryonGalleryState();
}

GoRoute _page(
  final String path, {
  final List<RouteBase> routes = const [],
  final List<Widget> anchors = const [],
}) => GoRoute(
  path: path,
  builder: (final _, final state) => Scaffold(
    body: Stack(
      children: [
        const SizedBox.expand(),
        Text(state.matchedLocation),
        ...anchors,
      ],
    ),
  ),
  routes: routes,
);

UserProfile _profile({final Avatar? avatar}) => UserProfile(
  userId: 'u1',
  name: 'n',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  avatar: avatar,
  isOnboarded: true,
  isTutorialCompleted: false,
);

class _FakeProfile extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => _profile();

  void emit(final UserProfile profile) => state = AsyncData(profile);
}

class _FakeRepository implements UserProfileRepository {
  @override
  Future<Result<UserProfile, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  ) async => Ok(_profile());

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late ProviderContainer container;
  late GoRouter router;
  late int prefetches;

  setUp(() {
    prefetches = 0;
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        shopCategoryImagesPrefetchProvider.overrideWith((final _) async {
          prefetches++;
        }),
        tutorialControllerProvider.overrideWith(_InactiveTutorial.new),
        tryonGalleryProvider.overrideWith(_EmptyGallery.new),
        wardrobeItemsProvider.overrideWith(
          () => FakeWardrobeItems([wardrobeItem('a')]),
        ),
      ],
    );
    addTearDown(container.dispose);

    router = GoRouter(
      initialLocation: AppRoutes.personalHome,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (final _, final _, final navigationShell) =>
              PersonalShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [_page(AppRoutes.personalHome)]),
            StatefulShellBranch(
              routes: [
                _page(AppRoutes.personalShop, routes: [_page('product/:id')]),
              ],
            ),
            StatefulShellBranch(routes: [_page(AppRoutes.personalChat)]),
            StatefulShellBranch(
              routes: [
                _page(AppRoutes.personalWardrobe, routes: [_page('item/:id')]),
              ],
            ),
            StatefulShellBranch(routes: [_page(AppRoutes.personalAccount)]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  Future<void> pumpShell(final WidgetTester tester) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );

  testWidgets('prefetches the shop category images once the shell opens', (
    final tester,
  ) async {
    await pumpShell(tester);
    router.go(AppRoutes.personalChat);
    await tester.pumpAndSettle();

    expect(prefetches, 1);
  });

  testWidgets('dock shows on a product page pushed from the home tab', (
    final tester,
  ) async {
    await pumpShell(tester);
    container.read(outfitTrayProvider.notifier).open();

    router.push(AppRoutes.personalShopProductPath('p1'));
    await tester.pumpAndSettle();

    expect(find.text('/personal/shop/product/p1'), findsOneWidget);
    expect(find.byKey(_dock), findsOneWidget);
  });

  testWidgets('dock shows on a wardrobe item page pushed from the chat tab', (
    final tester,
  ) async {
    await pumpShell(tester);
    router.go(AppRoutes.personalChat);
    await tester.pumpAndSettle();
    container.read(outfitTrayProvider.notifier).open();

    router.push(AppRoutes.personalWardrobeItemPath('a'));
    await tester.pumpAndSettle();

    expect(find.byKey(_dock), findsOneWidget);
  });

  testWidgets('dock hides again once the pushed garment page is popped', (
    final tester,
  ) async {
    await pumpShell(tester);
    container.read(outfitTrayProvider.notifier).open();
    router.push(AppRoutes.personalShopProductPath('p1'));
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text(AppRoutes.personalHome), findsOneWidget);
    expect(find.byKey(_dock), findsNothing);
  });

  testWidgets('dock stays hidden on the home tab while the tray is open', (
    final tester,
  ) async {
    await pumpShell(tester);
    container.read(outfitTrayProvider.notifier).open();
    await tester.pumpAndSettle();

    expect(find.byKey(_dock), findsNothing);
  });

  group('re-tapping the selected tab', () {
    Future<void> tapTab(
      final WidgetTester tester,
      final PersonalTab tab,
    ) async {
      await tester.tap(find.text(tab.label));
      await tester.pumpAndSettle();
    }

    TabReselect? reselect() => container.read(tabReselectSignalProvider);

    testWidgets('on the root page announces the tab', (final tester) async {
      await pumpShell(tester);

      await tapTab(tester, PersonalTab.home);

      expect(reselect()?.tab, PersonalTab.home);
    });

    testWidgets('on a pushed page pops back to the root without announcing', (
      final tester,
    ) async {
      await pumpShell(tester);
      await tapTab(tester, PersonalTab.wardrobe);
      router.push(AppRoutes.personalWardrobeItemPath('a'));
      await tester.pumpAndSettle();

      await tapTab(tester, PersonalTab.wardrobe);

      expect(find.text(AppRoutes.personalWardrobe), findsOneWidget);
      expect(reselect(), isNull);

      await tapTab(tester, PersonalTab.wardrobe);

      expect(reselect()?.tab, PersonalTab.wardrobe);
    });

    testWidgets(
      'on a garment page pushed from another branch pops back to the root',
      (final tester) async {
        await pumpShell(tester);
        router.push(AppRoutes.personalShopProductPath('p1'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<StatefulNavigationShell>(
                find.byType(StatefulNavigationShell),
              )
              .currentIndex,
          PersonalTab.home.index,
        );

        await tapTab(tester, PersonalTab.home);

        expect(find.text(AppRoutes.personalHome), findsOneWidget);
        expect(reselect(), isNull);
      },
    );

    testWidgets('switching to another tab does not announce', (
      final tester,
    ) async {
      await pumpShell(tester);

      await tapTab(tester, PersonalTab.chat);

      expect(find.text(AppRoutes.personalChat), findsOneWidget);
      expect(reselect(), isNull);
    });
  });

  group('first try-on tutorial', () {
    late ProviderContainer tutorialContainer;
    late GoRouter tutorialRouter;

    setUp(() {
      tutorialContainer = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          shopCategoryImagesPrefetchProvider.overrideWith((final _) async {}),
          userProfileProvider.overrideWith(_FakeProfile.new),
          completeTutorialUseCaseProvider.overrideWithValue(
            CompleteTutorial(_FakeRepository()),
          ),
          wardrobeItemsProvider.overrideWith(() => FakeWardrobeItems([])),
        ],
      );
      addTearDown(tutorialContainer.dispose);

      tutorialRouter = GoRouter(
        initialLocation: AppRoutes.personalHome,
        routes: [
          StatefulShellRoute.indexedStack(
            key: tutorialContainer.read(personalTabNavigatorProvider).shellKey,
            builder: (final _, final _, final navigationShell) =>
                PersonalShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(routes: [_page(AppRoutes.personalHome)]),
              StatefulShellBranch(
                routes: [
                  _page(
                    AppRoutes.personalShop,
                    anchors: const [
                      Center(
                        child: CoachMarkAnchor(
                          target: CoachMarkTarget.firstProductTryon,
                          child: SizedBox(width: 80, height: 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(routes: [_page(AppRoutes.personalChat)]),
              StatefulShellBranch(routes: [_page(AppRoutes.personalWardrobe)]),
              StatefulShellBranch(routes: [_page(AppRoutes.personalAccount)]),
            ],
          ),
        ],
      );
      addTearDown(tutorialRouter.dispose);
    });

    Future<void> settle(final WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
    }

    Finder visible(final String text) => find.text(text).hitTestable();

    testWidgets('walks from picking a model to the shop tab', (
      final tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: tutorialContainer,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: tutorialRouter,
            builder: (final context, final child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tutorialContainer.read(userProfileProvider.future);
      await settle(tester);

      expect(find.byKey(CoachMarkHint.bubbleKey), findsNothing);

      (tutorialContainer.read(userProfileProvider.notifier) as _FakeProfile)
          .emit(_profile(avatar: const Avatar.uploaded('u1/avatar/a.jpg')));
      await settle(tester);

      final shopTab = find.text(PersonalTab.shop.label);
      expect(visible(TutorialOverlay.shopTabMessage), findsOneWidget);
      expect(
        tester.getRect(find.byKey(CoachMarkHint.bubbleKey)).bottom,
        lessThan(tester.getRect(shopTab).top),
      );
      expect(
        tester.getCenter(find.byKey(CoachMarkHint.caretKey)).dx,
        moreOrLessEquals(tester.getCenter(shopTab).dx),
      );

      await tester.tap(shopTab);
      await settle(tester);

      expect(find.text(AppRoutes.personalShop), findsOneWidget);
      expect(find.text(TutorialOverlay.shopTabMessage), findsNothing);
      expect(visible(TutorialOverlay.tapTryonMessage), findsOneWidget);
      expect(
        tutorialContainer.read(tutorialControllerProvider),
        const TutorialState.startTryon(),
      );

      tutorialContainer
          .read(personalTabNavigatorProvider)
          .goTo(PersonalTab.home);
      await settle(tester);

      expect(visible(TutorialOverlay.shopTabMessage), findsOneWidget);
      expect(find.text(TutorialOverlay.tapTryonMessage), findsNothing);
    });
  });
}
