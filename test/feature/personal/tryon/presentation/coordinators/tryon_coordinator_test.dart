import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/coordinators/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';
import 'package:typed_result/typed_result.dart';

class _FakeAvatarUpload extends AvatarUploadNotifier {
  _FakeAvatarUpload(this._result);

  final Result<void, Failure> _result;
  final uploaded = <File>[];

  @override
  PendingAvatar? build() => null;

  @override
  Future<Result<void, Failure>> upload(final File image) async {
    uploaded.add(image);
    return _result;
  }
}

class _RecordingTryonController extends TryonController {
  final regenerated = <TryonGalleryEntry>[];

  @override
  TryonOutcome? build() => null;

  @override
  Future<void> regenerate(final TryonGalleryEntry entry) async {
    regenerated.add(entry);
  }
}

void main() {
  final photo = File('me.jpg');
  final entry = FinishedTryonEntry(
    const TryonResult(id: 't1', mode: TryonMode.image, imageUrl: 'u'),
    TryonSubject.generate(
      pieces: const [OutfitPiece.local(path: 'shirt.jpg')],
      mode: TryonMode.image,
    ),
  );

  late _FakeAvatarUpload avatarUpload;
  late _RecordingTryonController tryonController;

  TryonCoordinator coordinatorWith(final Result<void, Failure> uploadResult) {
    avatarUpload = _FakeAvatarUpload(uploadResult);
    tryonController = _RecordingTryonController();
    final container = ProviderContainer(
      overrides: [
        avatarUploadProvider.overrideWith(() => avatarUpload),
        tryonControllerProvider.overrideWith(() => tryonController),
      ],
    );
    addTearDown(container.dispose);
    return container.read(tryonCoordinatorProvider);
  }

  test('a saved photo tries the same outfit on again', () async {
    final coordinator = coordinatorWith(const Ok(null));

    final result = await coordinator.retryWithOwnPhoto(photo, entry);

    expect(result.isSuccess, isTrue);
    expect(avatarUpload.uploaded, [photo]);
    expect(tryonController.regenerated, [entry]);
  });

  test('a failed upload returns the failure and tries nothing on', () async {
    final coordinator = coordinatorWith(const Err(NetworkFailure()));

    final result = await coordinator.retryWithOwnPhoto(photo, entry);

    expect(result.getError(), isA<NetworkFailure>());
    expect(tryonController.regenerated, isEmpty);
  });
}
