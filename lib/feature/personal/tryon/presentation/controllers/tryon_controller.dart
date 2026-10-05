import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/outfit_piece.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/tryon.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:tryzeon/feature/personal/usage/providers/daily_usage_providers.dart';
import 'package:typed_result/typed_result.dart';
import 'package:uuid/uuid.dart';

part 'tryon_controller.g.dart';

@Riverpod(keepAlive: true)
class TryonController extends _$TryonController {
  static const _uuid = Uuid();

  @override
  TryonOutcome? build() {
    ref.watch(isAuthenticatedProvider);
    return null;
  }

  /// One-shot event lane: two identical outcomes in a row (e.g. two consecutive
  /// successes, which Dart canonicalizes to the same `const` instance) must both
  /// reach `ref.listen`, so every assignment notifies.
  @override
  bool updateShouldNotify(
    final TryonOutcome? previous,
    final TryonOutcome? next,
  ) => true;

  Future<void> tryonFromOutfit(
    final List<OutfitPiece> pieces, {
    final TryonMode mode = TryonMode.image,
  }) => _start(TryonSubject.generate(pieces: pieces, mode: mode));

  Future<void> regenerate(final TryonGalleryEntry entry) =>
      _start(entry.subject);

  /// Image generation is skipped, so only the transition style shapes the
  /// result. Takes the entry, not its result: the video inherits its subject.
  Future<void> animate(final FinishedTryonEntry entry) async {
    final imageUrl = entry.result.imageUrl;
    if (entry.mode != TryonMode.image || imageUrl == null || imageUrl.isEmpty) {
      state = const TryonFailed(ValidationFailure());
      return;
    }

    await _start(
      TryonSubject.animated(baseImageUrl: imageUrl, origin: entry.subject),
    );
  }

  Future<void> _start(final TryonSubject subject) async {
    // Setup runs before the placeholder exists, so its failures always speak up.
    String? customAvatarUrl;
    final TryonPreferences preferences;
    try {
      // An animate job dresses a finished picture, so it needs no avatar.
      if (subject is TryonSubjectGenerate) {
        customAvatarUrl = ref
            .read(tryonGalleryProvider)
            .customAvatarResult
            ?.imageUrl;
        final hasCustomAvatar =
            customAvatarUrl != null && customAvatarUrl.isNotEmpty;

        // Precondition: "no avatar at all" is a UI prompt, not a failure — check
        // it before inserting a placeholder so nothing flickers. The backend
        // answers NO_AVATAR either way, so this only saves a round trip.
        final profile = await ref.read(userProfileProvider.future);
        if (!hasCustomAvatar && !(profile?.avatarPath?.isNotEmpty ?? false)) {
          state = const TryonAvatarMissing();
          return;
        }
      }

      // Scene and styling apply to both modes — video renders its first frame
      // through the same image pass. Transition only reaches the video
      // generator.
      preferences = await ref.read(tryonPreferencesProvider.future);
    } catch (e, stackTrace) {
      AppLogger.error('Try-on setup failed', e, stackTrace);
      state = TryonFailed(mapExceptionToFailure(e));
      return;
    }

    final galleryNotifier = ref.read(tryonGalleryProvider.notifier);
    final id = _uuid.v4();

    // Before the request is built, because building it fetches images.
    galleryNotifier.addPending(id: id, subject: subject);

    // Past the placeholder everything recovers the same way. A `removeById`
    // that finds nothing means the user cancelled, so that run stays silent.
    try {
      final result = await ref.read(tryonUseCaseProvider)(
        TryonParams(
          requestId: id,
          subject: subject,
          preferences: preferences,
          customAvatarUrl: customAvatarUrl,
        ),
      );

      // Usage syncs even for a cancelled run — the generation was still spent.
      final usageCache = ref.read(dailyUsageTodayProvider.notifier);
      if (result.isSuccess) {
        final tryonResult = result.get()!;
        usageCache.syncFromSnapshot(tryonResult.usage);
        if (!galleryNotifier.complete(tryonResult)) return;
        state = const TryonSucceeded();
      } else {
        final failure = result.getError()!;
        usageCache.syncFromFailure(failure);
        if (!galleryNotifier.removeById(id)) return;
        state = switch (failure) {
          RateLimitFailure() => TryonRateLimited(
            isVideo: subject.mode == TryonMode.video,
          ),
          AvatarMissingFailure() => const TryonAvatarMissing(),
          _ => TryonFailed(failure),
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Try-on orchestration failed unexpectedly',
        e,
        stackTrace,
      );
      if (!galleryNotifier.removeById(id)) return;
      state = TryonFailed(mapExceptionToFailure(e));
    }
  }
}
