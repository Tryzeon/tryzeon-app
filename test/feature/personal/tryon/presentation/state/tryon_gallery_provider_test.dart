import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_report_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/report_tryon.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  _FakeUserProfileNotifier(this._initial);

  final Avatar _initial;

  @override
  Future<UserProfile?> build() async => UserProfile(
    userId: 'u1',
    isTutorialCompleted: true,
    name: 'n',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    avatar: _initial,
  );

  void replaceAvatar(final Avatar avatar) =>
      state = AsyncData(state.requireValue!.copyWith(avatar: avatar));
}

class _FakeReportRepository implements TryonReportRepository {
  Failure? failure;
  final reported = <String>[];

  @override
  Future<Result<void, Failure>> report(final String tryonId) async {
    reported.add(tryonId);
    if (failure case final failure?) return Err(failure);
    return const Ok(null);
  }
}

void main() {
  const piece = OutfitPiece.wardrobe(
    wardrobeItemId: 'w1',
    imagePath: 'w1.jpg',
    garmentType: GarmentType.top,
  );
  final imageSubject = TryonSubject(
    pieces: const [piece],
    mode: TryonMode.image,
  );
  final videoSubject = TryonSubject(
    pieces: const [piece],
    mode: TryonMode.video,
  );

  TryonGalleryNotifier makeNotifier() {
    final container = ProviderContainer(
      overrides: [isAuthenticatedProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);
    return container.read(tryonGalleryProvider.notifier);
  }

  test('a placeholder takes its mode from the subject it was started with', () {
    final notifier = makeNotifier()..addPending(id: 'a', subject: videoSubject);

    final entry = notifier.state.entries.single;
    expect(entry, isA<PendingTryonEntry>());
    expect(entry.mode, TryonMode.video);
  });

  test('the finished entry keeps the subject its own placeholder carried', () {
    // The one that finishes is not the first: with a single entry, a `complete`
    // reading the subject off the wrong row would still pass.
    final notifier = makeNotifier()
      ..addPending(id: 'a', subject: imageSubject)
      ..addPending(id: 'b', subject: videoSubject);

    final completed = notifier.complete(
      const TryonResult(id: 'b', mode: TryonMode.video, videoUrl: 'u'),
    );

    expect(completed, isTrue);
    final entry = notifier.state.entries.last;
    expect(entry, isA<FinishedTryonEntry>());
    expect(entry.subject, videoSubject);
  });

  test('completing an entry the user already dropped keeps it gone', () {
    final notifier = makeNotifier()..addPending(id: 'a', subject: imageSubject);
    notifier.removeById('a');

    final completed = notifier.complete(
      const TryonResult(id: 'a', mode: TryonMode.image, imageUrl: 'u'),
    );

    expect(completed, isFalse);
    expect(notifier.state.entries, isEmpty);
  });

  test('each entry keeps its own subject', () {
    final notifier = makeNotifier()
      ..addPending(id: 'a', subject: imageSubject)
      ..addPending(id: 'b', subject: videoSubject);

    expect(notifier.state.entries.map((final e) => e.subject), [
      imageSubject,
      videoSubject,
    ]);
  });

  test('the finished entry keeps the pieces its placeholder carried', () {
    final notifier = makeNotifier()..addPending(id: 'a', subject: imageSubject);

    notifier.complete(
      const TryonResult(id: 'a', mode: TryonMode.image, imageUrl: 'u'),
    );

    expect(notifier.state.entries.single.pieces, const [piece]);
  });

  for (final (from, to) in const [
    (
      Avatar.uploaded('u1/avatar/old.jpg'),
      Avatar.uploaded('u1/avatar/new.jpg'),
    ),
    (Avatar.preset(PresetAvatar.female), Avatar.preset(PresetAvatar.male)),
    (Avatar.preset(PresetAvatar.female), Avatar.uploaded('u1/avatar/new.jpg')),
  ]) {
    test('replacing $from with $to returns to the avatar page', () async {
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          userProfileProvider.overrideWith(
            () => _FakeUserProfileNotifier(from),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(tryonGalleryProvider.notifier);
      await container.read(userProfileProvider.future);

      notifier
        ..addPending(id: 'a', subject: imageSubject)
        ..complete(
          const TryonResult(id: 'a', mode: TryonMode.image, imageUrl: 'u'),
        );
      expect(notifier.state.isAvatarPage, isFalse);

      (container.read(userProfileProvider.notifier) as _FakeUserProfileNotifier)
          .replaceAvatar(to);

      final state = container.read(tryonGalleryProvider);
      expect(state.isAvatarPage, isTrue);
      expect(state.entries.single.id, 'a');
    });
  }

  test('showing the avatar leaves the entries in place', () {
    final notifier = makeNotifier()
      ..addPending(id: 'a', subject: imageSubject)
      ..showAvatar();

    expect(notifier.state.isAvatarPage, isTrue);
    expect(notifier.state.entries.single.id, 'a');
  });

  group('report', () {
    late _FakeReportRepository reports;

    TryonGalleryNotifier makeReportingNotifier() {
      reports = _FakeReportRepository();
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          reportTryonUseCaseProvider.overrideWithValue(
            ReportTryon(reportRepository: reports),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container.read(tryonGalleryProvider.notifier)
        ..addPending(id: 'a', subject: imageSubject)
        ..complete(const TryonResult(id: 'a', mode: TryonMode.image));
    }

    test('removes the entry once the report is sent', () async {
      final notifier = makeReportingNotifier();

      final result = await notifier.report('a');

      expect(result.isSuccess, isTrue);
      expect(reports.reported, ['a']);
      expect(notifier.state.entries, isEmpty);
    });

    test('keeps the entry when the report fails', () async {
      final notifier = makeReportingNotifier();
      reports.failure = const NetworkFailure();

      final result = await notifier.report('a');

      expect(result.getError(), isA<NetworkFailure>());
      expect(notifier.state.entries.single.id, 'a');
    });
  });
}
