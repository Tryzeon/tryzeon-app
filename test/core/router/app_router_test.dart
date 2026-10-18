import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/modules/auth_identity/domain/services/auth_identity_service.dart';
import 'package:tryzeon/core/router/app_router.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

import '../../support/store_test_doubles.dart';

class _SignedIn implements AuthIdentityService {
  @override
  String? get currentUserId => 'u1';

  @override
  Stream<String?> watchUserId() => const Stream.empty();
}

class _FakeAnalytics extends Fake implements FirebaseAnalytics {}

class _FakeStoreProfile extends StoreProfileNotifier {
  @override
  Future<StoreProfile?> build() async => storeProfile();

  void emit(final StoreProfile? profile) => state = AsyncData(profile);
}

UserProfile _userProfile({
  final String name = 'n',
  final bool isOnboarded = true,
}) => UserProfile(
  userId: 'u1',
  name: name,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  isOnboarded: isOnboarded,
  isTutorialCompleted: true,
);

class _FakeUserProfile extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => _userProfile();

  void emit(final UserProfile? profile) => state = AsyncData(profile);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late int refreshes;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        authIdentityServiceProvider.overrideWithValue(_SignedIn()),
        firebaseAnalyticsProvider.overrideWithValue(_FakeAnalytics()),
        storeProfileProvider.overrideWith(_FakeStoreProfile.new),
        userProfileProvider.overrideWith(_FakeUserProfile.new),
      ],
    );
    addTearDown(container.dispose);

    final router = container.listen(appRouterProvider, (final _, final _) {});
    await container.read(storeProfileProvider.future);
    await container.read(userProfileProvider.future);

    refreshes = 0;
    router.read().routeInformationProvider.addListener(() => refreshes++);
  });

  _FakeStoreProfile store() =>
      container.read(storeProfileProvider.notifier) as _FakeStoreProfile;
  _FakeUserProfile user() =>
      container.read(userProfileProvider.notifier) as _FakeUserProfile;

  group('store profile', () {
    test('an edit to its contents leaves the route stack alone', () {
      store().emit(storeProfile(name: 'renamed'));

      expect(refreshes, 0);
    });

    test('losing the profile re-runs the onboarding redirect', () {
      store().emit(null);

      expect(refreshes, 1);
    });
  });

  group('user profile', () {
    test('an edit to its contents leaves the route stack alone', () {
      user().emit(_userProfile(name: 'renamed'));

      expect(refreshes, 0);
    });

    test('a change in onboarding status re-runs the onboarding redirect', () {
      user().emit(_userProfile(isOnboarded: false));

      expect(refreshes, 1);
    });
  });
}
