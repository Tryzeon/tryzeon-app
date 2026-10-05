import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/tryon.dart';
import 'package:typed_result/typed_result.dart';

class _CapturingTryonRepository implements TryonRepository {
  final List<TryonRequest> requests = [];

  @override
  Future<Result<TryonResult, Failure>> tryon(final TryonRequest request) async {
    requests.add(request);
    return Ok(
      TryonResult(id: request.requestId, mode: request.mode, imageUrl: 'u'),
    );
  }
}

class _FakeMediaRepository implements TryonMediaRepository {
  final Map<String, List<int>> remote = {};
  final Map<String, List<int>> local = {};

  @override
  Future<Result<Uint8List, Failure>> loadImageBytes(final String url) async =>
      Ok(Uint8List.fromList(remote[url]!));

  @override
  Future<Result<Uint8List, Failure>> loadLocalImageBytes(
    final String path,
  ) async {
    final bytes = local[path];
    return bytes == null
        ? const Err(UnknownFailure())
        : Ok(Uint8List.fromList(bytes));
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _CapturingTryonRepository tryonRepository;
  late _FakeMediaRepository media;
  late Tryon tryon;

  const preferences = TryonPreferences(
    scenePrompt: 'beach',
    stylingPrompt: 'tucked',
    transitionPrompt: 'spin',
  );
  const wardrobe = OutfitPiece.wardrobe(
    wardrobeItemId: 'w1',
    imagePath: 'w1.jpg',
    garmentType: GarmentType.top,
  );

  setUp(() {
    tryonRepository = _CapturingTryonRepository();
    media = _FakeMediaRepository();
    tryon = Tryon(tryonRepository: tryonRepository, mediaRepository: media);
  });

  test('an image generate request carries prompts but no transition', () async {
    await tryon(
      const TryonParams(
        requestId: 'r1',
        subject: TryonSubject.generate(
          pieces: [wardrobe],
          mode: TryonMode.image,
        ),
        preferences: preferences,
      ),
    );

    final request = tryonRepository.requests.single as TryonGenerateRequest;
    expect(request.garments, const [
      TryonGarment.wardrobe(wardrobeItemId: 'w1'),
    ]);
    expect(request.scenePrompt, 'beach');
    expect(request.transitionPrompt, isNull);
    expect(request.avatarBase64, isNull);
  });

  test('a video generate request carries the transition prompt', () async {
    await tryon(
      const TryonParams(
        requestId: 'r1',
        subject: TryonSubject.generate(
          pieces: [wardrobe],
          mode: TryonMode.video,
        ),
        preferences: preferences,
      ),
    );

    final request = tryonRepository.requests.single as TryonGenerateRequest;
    expect(request.transitionPrompt, 'spin');
  });

  test('local pieces and a custom avatar are sent as base64', () async {
    media
      ..local['g.jpg'] = [1, 2, 3]
      ..remote['https://x/avatar.jpg'] = [4, 5];

    await tryon(
      const TryonParams(
        requestId: 'r1',
        subject: TryonSubject.generate(
          pieces: [OutfitPiece.local(path: 'g.jpg')],
          mode: TryonMode.image,
        ),
        preferences: preferences,
        customAvatarUrl: 'https://x/avatar.jpg',
      ),
    );

    final request = tryonRepository.requests.single as TryonGenerateRequest;
    expect(request.garments, [
      TryonGarment.images(
        base64Images: [
          base64Encode([1, 2, 3]),
        ],
      ),
    ]);
    expect(request.avatarBase64, base64Encode([4, 5]));
  });

  test('an animate request sends the base picture', () async {
    media.remote['https://x/base.jpg'] = [9];

    await tryon(
      const TryonParams(
        requestId: 'r1',
        subject: TryonSubject.animated(
          baseImageUrl: 'https://x/base.jpg',
          origin: TryonSubject.generate(
            pieces: [wardrobe],
            mode: TryonMode.image,
          ),
        ),
        preferences: preferences,
      ),
    );

    final request = tryonRepository.requests.single as TryonAnimateRequest;
    expect(request.baseImageBase64, base64Encode([9]));
    expect(request.transitionPrompt, 'spin');
  });

  test('an unreadable local piece fails without calling the backend', () async {
    final result = await tryon(
      const TryonParams(
        requestId: 'r1',
        subject: TryonSubject.generate(
          pieces: [OutfitPiece.local(path: 'missing.jpg')],
          mode: TryonMode.image,
        ),
        preferences: preferences,
      ),
    );

    expect(result.isFailure, isTrue);
    expect(tryonRepository.requests, isEmpty);
  });
}
