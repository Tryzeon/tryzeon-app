import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
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
import 'package:tryzeon/feature/personal/tryon/domain/usecases/load_image_as_base64.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/tryon.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/usage/providers/daily_usage_providers.dart';
import 'package:typed_result/typed_result.dart';

class _CapturingTryonRepository implements TryonRepository {
  final List<TryonRequest> requests = [];

  @override
  Future<Result<TryonResult, Failure>> tryon(final TryonRequest request) async {
    requests.add(request);
    return Ok(TryonResult(id: request.requestId, mode: request.mode, imageUrl: 'u'));
  }
}

class _UncalledTryonMediaRepository implements TryonMediaRepository {
  @override
  Future<Result<Uint8List, Failure>> loadImageBytes(final String url) =>
      throw UnimplementedError('wardrobe garments never load an image by url');

  @override
  Future<Result<void, Failure>> saveToGallery(final TryonResult result) =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> share(final TryonResult result) =>
      throw UnimplementedError();
}

class _FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => UserProfile(
    userId: 'u1',
    name: 'n',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    avatarPath: 'u1/avatar.jpg',
  );
}

class _FakeTryonPreferencesNotifier extends TryonPreferencesNotifier {
  @override
  Future<TryonPreferences> build() async => const TryonPreferences();
}

class _FakeDailyUsageToday extends DailyUsageToday {
  @override
  Future<DailyUsage> build() async => DailyUsage(
    userId: 'u1',
    usageDate: DateTime(2026),
    tryonCount: 0,
    chatCount: 0,
    videoCount: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CapturingTryonRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _CapturingTryonRepository();
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        userProfileProvider.overrideWith(_FakeUserProfileNotifier.new),
        tryonPreferencesProvider.overrideWith(_FakeTryonPreferencesNotifier.new),
        dailyUsageTodayProvider.overrideWith(_FakeDailyUsageToday.new),
        tryonUseCaseProvider.overrideWithValue(Tryon(tryonRepository: repository)),
        loadImageAsBase64UseCaseProvider.overrideWithValue(
          LoadImageAsBase64(mediaRepository: _UncalledTryonMediaRepository()),
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
    name: 'Tee',
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

    final request = repository.requests.single as TryonGenerateRequest;
    expect(request.garments, const [
      TryonGarment.wardrobe(wardrobeItemId: 'w1'),
      TryonGarment.product(productId: 'p1', sizeId: 'M'),
      TryonGarment.wardrobe(wardrobeItemId: 'w2'),
    ]);
    expect(request.mode, TryonMode.image);
  });

  test('a local piece is sent as inline image bytes', () async {
    final dir = await Directory.systemTemp.createTemp('outfit');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/g.jpg')..writeAsBytesSync([1, 2, 3]);

    await container.read(tryonControllerProvider.notifier).tryonFromOutfit([
      OutfitPiece.local(path: file.path),
    ]);

    final request = repository.requests.single as TryonGenerateRequest;
    expect(request.garments, [
      TryonGarment.images(
        base64Images: [
          base64Encode([1, 2, 3]),
        ],
      ),
    ]);
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
      const TryonSubject.generate(pieces: [w1, w2], mode: TryonMode.video),
    );
  });
}
