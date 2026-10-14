import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/tutorial/domain/usecases/complete_tutorial.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/controllers/tutorial_controller.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/state/tutorial_state.dart';
import 'package:tryzeon/feature/personal/tutorial/providers/tutorial_providers.dart';
import 'package:typed_result/typed_result.dart';

UserProfile _profile({
  final bool isOnboarded = true,
  final bool isTutorialCompleted = false,
  final String? avatarPath,
  final String name = 'n',
}) => UserProfile(
  userId: 'u1',
  name: name,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  avatarPath: avatarPath,
  isOnboarded: isOnboarded,
  isTutorialCompleted: isTutorialCompleted,
);

class _FakeProfile extends UserProfileNotifier {
  _FakeProfile(this._initial);

  final UserProfile _initial;

  @override
  Future<UserProfile?> build() async => _initial;

  void emit(final UserProfile profile) => state = AsyncData(profile);
}

class _NeverProfile extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() => Completer<UserProfile?>().future;
}

final _authFlag = NotifierProvider<_AuthFlag, bool>(_AuthFlag.new);

class _AuthFlag extends Notifier<bool> {
  @override
  bool build() => true;

  bool get value => state;

  set value(final bool value) => state = value;
}

class _FakeTryonController extends TryonController {
  @override
  TryonOutcome? build() => null;

  TryonOutcome? get outcome => state;

  set outcome(final TryonOutcome? outcome) => state = outcome;
}

class _FakeRating extends TryonRatingController {
  @override
  TryonRatingState build() => const TryonRatingState();

  void like(final String id) => state = state.copyWith(
    feedback: {...state.feedback, id: const TryonFeedback.like()},
  );
}

class _FakeRepository implements UserProfileRepository {
  _FakeRepository({this.fails = false});

  final bool fails;
  final updates = <UserProfileUpdate>[];

  @override
  Future<Result<void, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  ) async {
    updates.add(update);
    return fails ? const Err(ValidationFailure()) : const Ok(null);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final _subject = TryonSubject.generate(
  pieces: const [
    OutfitPiece.wardrobe(
      wardrobeItemId: 'w1',
      imagePath: 'w1.jpg',
      garmentType: GarmentType.top,
    ),
  ],
  mode: TryonMode.image,
);

void main() {
  late ProviderContainer container;
  late _FakeRepository repository;

  Future<void> start(
    final UserProfile profile, {
    final bool fails = false,
  }) async {
    repository = _FakeRepository(fails: fails);
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith(
          (final ref) => ref.watch(_authFlag),
        ),
        userProfileProvider.overrideWith(() => _FakeProfile(profile)),
        tryonControllerProvider.overrideWith(_FakeTryonController.new),
        tryonRatingControllerProvider.overrideWith(_FakeRating.new),
        completeTutorialUseCaseProvider.overrideWithValue(
          CompleteTutorial(repository),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(tutorialControllerProvider, (final _, final _) {});
    await container.read(userProfileProvider.future);
  }

  TutorialState state() => container.read(tutorialControllerProvider);
  TutorialController controller() =>
      container.read(tutorialControllerProvider.notifier);
  _FakeProfile profile() =>
      container.read(userProfileProvider.notifier) as _FakeProfile;
  _FakeTryonController tryon() =>
      container.read(tryonControllerProvider.notifier) as _FakeTryonController;
  void addPending(final String id) => container
      .read(tryonGalleryProvider.notifier)
      .addPending(id: id, subject: _subject);
  void succeed(final String id) => tryon().outcome = TryonSucceeded(
    TryonResult(id: id, mode: TryonMode.image),
  );

  test('inactive for a profile that has not onboarded', () async {
    await start(_profile(isOnboarded: false));
    expect(state(), const TutorialState.inactive());
  });

  test('inactive once the tutorial is completed', () async {
    await start(_profile(isTutorialCompleted: true));
    expect(state(), const TutorialState.inactive());
  });

  test('asks for a model first, then moves on once one is set', () async {
    await start(_profile());
    expect(state(), const TutorialState.pickModel());

    profile().emit(_profile(avatarPath: 'u1/avatar/a.jpg'));

    expect(state(), const TutorialState.startTryon());
  });

  test('a new pending try-on starts generating', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));

    addPending('r1');

    expect(state(), const TutorialState.generating({'r1'}));
  });

  test('keeps generating when the profile re-emits', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');

    profile().emit(_profile(avatarPath: 'u1/avatar/a.jpg', name: 'n2'));

    expect(state(), const TutorialState.generating({'r1'}));
  });

  test('keeps the review step when the profile re-emits', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');
    succeed('r1');

    profile().emit(_profile(avatarPath: 'u1/avatar/a.jpg', name: 'n2'));

    expect(state(), const TutorialState.reviewResult('r1'));
  });

  test('inactive while the profile is still loading', () async {
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        userProfileProvider.overrideWith(_NeverProfile.new),
      ],
    );
    addTearDown(container.dispose);

    container.listen(tutorialControllerProvider, (final _, final _) {});

    expect(state(), const TutorialState.inactive());
  });

  test('logging out and back in restarts the tutorial', () async {
    await start(_profile());
    await controller().complete();
    expect(state(), const TutorialState.inactive());

    container.read(_authFlag.notifier).value = false;
    await pumpEventQueue();
    container.read(_authFlag.notifier).value = true;
    await pumpEventQueue();
    profile().emit(_profile(name: 'n2'));

    expect(state(), const TutorialState.pickModel());
  });

  test('a missing-avatar outcome with an avatar present retries', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');

    tryon().outcome = const TryonAvatarMissing('r1');

    expect(state(), const TutorialState.startTryon());
  });

  test('ignores outcomes for other requests', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');

    tryon().outcome = TryonSucceeded(
      const TryonResult(id: 'other', mode: TryonMode.image),
    );

    expect(state(), const TutorialState.generating({'r1'}));
  });

  test('success moves to the review step and persists completion', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');

    succeed('r1');
    await pumpEventQueue();

    expect(state(), const TutorialState.reviewResult('r1'));
    expect(repository.updates, [
      const UserProfileUpdate(isTutorialCompleted: true),
    ]);
  });

  test('done after the review step hides without writing again', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');
    succeed('r1');
    await pumpEventQueue();

    await controller().complete();

    expect(state(), const TutorialState.inactive());
    expect(repository.updates, hasLength(1));
  });

  test('the review step survives a profile re-emit marked completed', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');
    succeed('r1');
    await pumpEventQueue();

    profile().emit(
      _profile(avatarPath: 'u1/avatar/a.jpg', isTutorialCompleted: true),
    );

    expect(state(), const TutorialState.reviewResult('r1'));
  });

  test('a failed persist keeps the review step, then stays done', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'), fails: true);
    addPending('r1');
    succeed('r1');
    await pumpEventQueue();
    expect(state(), const TutorialState.reviewResult('r1'));

    await controller().complete();
    profile().emit(_profile(avatarPath: 'u1/avatar/a.jpg', name: 'n2'));

    expect(state(), const TutorialState.inactive());
    expect(repository.updates, hasLength(1));
  });

  test('a failed persist is logged as an error', () async {
    AppLogger.talker.cleanHistory();
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'), fails: true);
    addPending('r1');
    succeed('r1');
    await pumpEventQueue();

    expect(
      AppLogger.talker.history.where(
        (final log) =>
            log.logLevel == LogLevel.error &&
            (log.message ?? '').contains('Failed to mark the tutorial'),
      ),
      hasLength(1),
    );
  });

  test('tracks every try-on started while waiting', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');
    addPending('r2');
    expect(state(), const TutorialState.generating({'r1', 'r2'}));

    tryon().outcome = const TryonFailed('r1', ValidationFailure());
    expect(state(), const TutorialState.generating({'r2'}));

    succeed('r2');
    expect(state(), const TutorialState.reviewResult('r2'));
  });

  test(
    'returns to starting a try-on only once every tracked one failed',
    () async {
      await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
      addPending('r1');
      addPending('r2');

      tryon().outcome = const TryonCancelled('r2');
      tryon().outcome = const TryonFailed('r1', ValidationFailure());

      expect(state(), const TutorialState.startTryon());
    },
  );

  test('failure and cancel return to starting a try-on', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');
    tryon().outcome = const TryonFailed('r1', ValidationFailure());
    expect(state(), const TutorialState.startTryon());

    addPending('r2');
    tryon().outcome = const TryonCancelled('r2');
    expect(state(), const TutorialState.startTryon());
  });

  test('hitting the daily limit completes the tutorial', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');

    tryon().outcome = const TryonRateLimited('r1', isVideo: false);
    await pumpEventQueue();

    expect(state(), const TutorialState.inactive());
    expect(repository.updates, [
      const UserProfileUpdate(isTutorialCompleted: true),
    ]);
  });

  test('rating the reviewed result hides without writing again', () async {
    await start(_profile(avatarPath: 'u1/avatar/a.jpg'));
    addPending('r1');
    succeed('r1');
    await pumpEventQueue();

    (container.read(tryonRatingControllerProvider.notifier) as _FakeRating)
        .like('r1');
    await pumpEventQueue();

    expect(state(), const TutorialState.inactive());
    expect(repository.updates, hasLength(1));
  });

  test('completing twice writes once', () async {
    await start(_profile());

    await controller().complete();
    await controller().complete();

    expect(repository.updates, hasLength(1));
  });

  test('stays inactive for the session when completing fails', () async {
    await start(_profile(), fails: true);

    await controller().complete();
    profile().emit(_profile(avatarPath: 'u1/avatar/a.jpg'));

    expect(state(), const TutorialState.inactive());
  });
}
