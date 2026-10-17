import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/state/tutorial_state.dart';
import 'package:typed_result/typed_result.dart';

part 'tutorial_controller.g.dart';

/// Listens instead of watching the profile: a refresh mid try-on must not
/// rebuild the controller and drop the request it is waiting on.
@Riverpod(keepAlive: true)
class TutorialController extends _$TutorialController {
  var _dismissed = false;
  var _persisted = false;

  @override
  TutorialState build() {
    ref.watch(isAuthenticatedProvider);
    _dismissed = false;
    _persisted = false;

    ref.listen(userProfileProvider, (final _, final next) {
      if (!next.hasValue) return;
      state = _baseline(next.value, current: state);
    });
    ref.listen(tryonGalleryProvider, _onGallery);
    ref.listen(tryonControllerProvider, (final _, final outcome) {
      if (outcome != null) _onOutcome(outcome);
    });
    ref.listen(tryonRatingControllerProvider, (final _, final next) {
      if (state case TutorialReviewResult(
        :final requestId,
      ) when next.feedback.containsKey(requestId)) {
        unawaited(complete());
      }
    });

    return _baseline(
      ref.read(userProfileProvider).value,
      current: const TutorialState.inactive(),
    );
  }

  Future<void> complete() async {
    _dismissed = true;
    state = const TutorialState.inactive();
    await _persist();
  }

  Future<void> _persist() async {
    if (_persisted) return;
    _persisted = true;

    final result = await ref
        .read(userProfileProvider.notifier)
        .completeTutorial();
    if (result.isFailure) {
      AppLogger.error(
        'Failed to mark the tutorial completed',
        result.getError(),
      );
    }
  }

  TutorialState _baseline(
    final UserProfile? profile, {
    required final TutorialState current,
  }) {
    if (_dismissed || profile == null || !profile.isOnboarded) {
      return const TutorialState.inactive();
    }
    if (current is TutorialReviewResult) return current;
    if (profile.isTutorialCompleted) return const TutorialState.inactive();
    if (!profile.hasAvatar) return const TutorialState.pickModel();
    return switch (current) {
      TutorialGenerating() => current,
      _ => const TutorialState.startTryon(),
    };
  }

  void _onGallery(
    final TryonGalleryState? previous,
    final TryonGalleryState next,
  ) {
    final tracked = switch (state) {
      TutorialStartTryon() => const <String>{},
      TutorialGenerating(:final requestIds) => requestIds,
      _ => null,
    };
    if (tracked == null) return;
    final known = {...?previous?.entries.map((final e) => e.id)};
    final started = next.entries
        .whereType<PendingTryonEntry>()
        .map((final e) => e.id)
        .where((final id) => !known.contains(id));
    if (started.isEmpty) return;
    state = TutorialState.generating({...tracked, ...started});
  }

  void _onOutcome(final TryonOutcome outcome) {
    final waiting = state;
    if (waiting is! TutorialGenerating ||
        !waiting.requestIds.contains(outcome.requestId)) {
      return;
    }
    final remaining = {...waiting.requestIds}..remove(outcome.requestId);
    switch (outcome) {
      case TryonSucceeded():
        state = TutorialState.reviewResult(outcome.requestId);
        unawaited(_persist());
      case TryonRateLimited():
        unawaited(complete());
      case TryonFailed() || TryonCancelled() when remaining.isNotEmpty:
        state = TutorialState.generating(remaining);
      case TryonFailed() || TryonCancelled():
        state = const TutorialState.startTryon();
      case TryonAvatarMissing():
        state = _baseline(
          ref.read(userProfileProvider).value,
          current: remaining.isEmpty
              ? const TutorialState.startTryon()
              : TutorialState.generating(remaining),
        );
    }
  }
}
