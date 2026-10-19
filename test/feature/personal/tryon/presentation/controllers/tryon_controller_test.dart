import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/tryon.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:tryzeon/feature/personal/usage/providers/usage_quota_providers.dart';
import 'package:typed_result/typed_result.dart';

class _CapturingTryonRepository implements TryonRepository {
  final List<TryonRequest> requests = [];
  Future<Result<TryonResult, Failure>> Function(TryonRequest request)? respond;

  @override
  Future<Result<TryonResult, Failure>> tryon(final TryonRequest request) async {
    requests.add(request);
    return respond?.call(request) ??
        Ok(
          TryonResult(id: request.requestId, mode: request.mode, imageUrl: 'u'),
        );
  }
}

class _UncalledTryonMediaRepository implements TryonMediaRepository {
  @override
  Future<Result<void, Failure>> share({
    required final String url,
    required final TryonMode mode,
  }) => throw UnimplementedError();

  @override
  Future<Result<Uint8List, Failure>> loadLocalImageBytes(final String path) =>
      throw UnimplementedError('wardrobe garments never read a local file');
}

class _FakeUserProfileNotifier extends UserProfileNotifier {
  _FakeUserProfileNotifier({
    this.avatar = const Avatar.uploaded('u1/avatar.jpg'),
  });

  final Avatar? avatar;

  @override
  Future<UserProfile?> build() async => UserProfile(
    userId: 'u1',
    isTutorialCompleted: true,
    name: 'n',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    avatar: avatar,
  );
}

class _FakeTryonPreferencesNotifier extends TryonPreferencesNotifier {
  @override
  Future<TryonPreferences> build() async => const TryonPreferences();
}

UsageQuota _freeQuota({final int tryonImageUsed = 0}) => UsageQuota(
  tier: AppSubscriptionTier.free,
  period: QuotaPeriod.day,
  resetsAt: DateTime.utc(2026, 1, 1, 16),
  tryonImage: FeatureQuota(used: tryonImageUsed, quota: 10),
  tryonVideo: const FeatureQuota(used: 0, quota: 0),
);

class _FakeUsageQuotaNotifier extends UsageQuotaNotifier {
  static int refreshes = 0;

  @override
  Future<UsageQuota> build() async => _freeQuota();

  @override
  Future<Result<void, Failure>> refresh() async {
    refreshes++;
    state = AsyncData(_freeQuota(tryonImageUsed: 1));
    return const Ok(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CapturingTryonRepository repository;
  late ProviderContainer container;

  setUp(() {
    _FakeUsageQuotaNotifier.refreshes = 0;
    repository = _CapturingTryonRepository();
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        userProfileProvider.overrideWith(_FakeUserProfileNotifier.new),
        tryonPreferencesProvider.overrideWith(
          _FakeTryonPreferencesNotifier.new,
        ),
        usageQuotaProvider.overrideWith(_FakeUsageQuotaNotifier.new),
        tryonUseCaseProvider.overrideWithValue(
          Tryon(
            tryonRepository: repository,
            mediaRepository: _UncalledTryonMediaRepository(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  const w1 = OutfitPiece.wardrobe(
    wardrobeItemId: 'w1',
    imagePath: 'w1.jpg',
    garmentType: GarmentType.top,
  );
  const w2 = OutfitPiece.wardrobe(
    wardrobeItemId: 'w2',
    imagePath: 'w2.jpg',
    garmentType: GarmentType.pants,
  );
  const p1 = OutfitPiece.product(
    productId: 'p1',
    imageUrl: 'https://x/p1.jpg',
    garmentType: GarmentType.top,
    sizeId: 'M',
  );

  test('tryonFromOutfit sends one garment per piece, in order', () async {
    await container.read(tryonControllerProvider.notifier).tryonFromOutfit([
      w1,
      p1,
      w2,
    ], mode: TryonMode.image);

    final request = repository.requests.single;
    expect(request.garments, const [
      TryonGarment.wardrobe(wardrobeItemId: 'w1'),
      TryonGarment.product(productId: 'p1', sizeId: 'M'),
      TryonGarment.wardrobe(wardrobeItemId: 'w2'),
    ]);
    expect(request.mode, TryonMode.image);
  });

  test('the finished gallery entry keeps its pieces and subject', () async {
    await container.read(tryonControllerProvider.notifier).tryonFromOutfit([
      w1,
      w2,
    ], mode: TryonMode.video);

    final entry = container.read(tryonGalleryProvider).entries.single;
    expect(entry, isA<FinishedTryonEntry>());
    expect(entry.pieces, [w1, w2]);
    expect(
      entry.subject,
      TryonSubject(pieces: const [w1, w2], mode: TryonMode.video),
    );
  });

  group('outcomes', () {
    late List<TryonOutcome?> outcomes;

    setUp(() {
      outcomes = [];
      container.listen(
        tryonControllerProvider,
        (final _, final next) => outcomes.add(next),
      );
    });

    test('a success carries the gallery entry id and its result', () async {
      await container.read(tryonControllerProvider.notifier).tryonFromOutfit([
        w1,
      ]);

      final entry = container.read(tryonGalleryProvider).entries.single;
      final outcome = outcomes.single! as TryonSucceeded;
      expect(outcome.requestId, entry.id);
      expect(outcome.result, entry.result);
    });

    test('a success re-reads the quota', () async {
      await container.read(usageQuotaProvider.future);

      await container.read(tryonControllerProvider.notifier).tryonFromOutfit([
        w1,
      ]);

      expect(_FakeUsageQuotaNotifier.refreshes, 1);
      expect(
        container.read(usageQuotaProvider).value,
        _freeQuota(tryonImageUsed: 1),
      );
    });

    test('a failure carries the id of the request that failed', () async {
      repository.respond = (final _) async => const Err(RateLimitFailure());

      await container.read(tryonControllerProvider.notifier).tryonFromOutfit([
        w1,
      ]);

      final outcome = outcomes.single! as TryonRateLimited;
      expect(outcome.requestId, repository.requests.single.requestId);
      expect(container.read(tryonGalleryProvider).entries, isEmpty);
    });

    for (final (label, response)
        in <(String, Result<TryonResult, Failure> Function(TryonRequest))>[
          (
            'succeeds',
            (final TryonRequest r) =>
                Ok(TryonResult(id: r.requestId, mode: r.mode, imageUrl: 'u')),
          ),
          ('fails', (final TryonRequest _) => const Err(ServerFailure())),
        ]) {
      test('dropping the pending entry reports a cancellation when the run '
          '$label', () async {
        final gate = Completer<void>();
        repository.respond = (final request) async {
          await gate.future;
          return response(request);
        };

        final run = container
            .read(tryonControllerProvider.notifier)
            .tryonFromOutfit([w1]);
        await pumpEventQueue();
        final id = repository.requests.single.requestId;
        container.read(tryonGalleryProvider.notifier).removeById(id);
        gate.complete();
        await run;

        final outcome = outcomes.single! as TryonCancelled;
        expect(outcome.requestId, id);
      });
    }

    test('a missing avatar is reported without placing an entry', () async {
      final noAvatar = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          userProfileProvider.overrideWith(
            () => _FakeUserProfileNotifier(avatar: null),
          ),
        ],
      );
      addTearDown(noAvatar.dispose);
      final missing = <TryonOutcome?>[];
      noAvatar.listen(
        tryonControllerProvider,
        (final _, final next) => missing.add(next),
      );

      await noAvatar.read(tryonControllerProvider.notifier).tryonFromOutfit([
        w1,
      ]);

      expect(missing.single, isA<TryonAvatarMissing>());
      expect(noAvatar.read(tryonGalleryProvider).entries, isEmpty);
    });
  });
}
