import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_feedback.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/rate_tryon.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'tryon_rating_controller.freezed.dart';
part 'tryon_rating_controller.g.dart';

@freezed
sealed class TryonRatingState with _$TryonRatingState {
  const factory TryonRatingState({
    @Default(<String, TryonFeedback>{})
    final Map<String, TryonFeedback> feedback,
    @Default(<String>{}) final Set<String> saving,
  }) = _TryonRatingState;
}

/// One save per try-on is in flight at a time, so responses cannot land out of
/// order and leave the server disagreeing with the screen.
@Riverpod(keepAlive: true)
class TryonRatingController extends _$TryonRatingController {
  @override
  TryonRatingState build() {
    ref.watch(isAuthenticatedProvider);
    return const TryonRatingState();
  }

  Future<Result<void, Failure>> toggle(
    final String tryonId,
    final TryonFeedback tapped,
  ) async {
    if (state.saving.contains(tryonId)) return const Ok(null);

    final previous = state.feedback[tryonId];
    final tappedAgain = switch ((previous, tapped)) {
      (TryonLike(), TryonLike()) || (TryonDislike(), TryonDislike()) => true,
      _ => false,
    };
    _show(tryonId, tappedAgain ? null : tapped);
    return _save(tryonId, lastSaved: previous);
  }

  Future<Result<void, Failure>> explain(
    final String tryonId,
    final TryonDislike explanation,
  ) async {
    final current = state.feedback[tryonId];
    if (current is! TryonDislike || state.saving.contains(tryonId)) {
      return const Ok(null);
    }

    _show(tryonId, explanation);
    return _save(tryonId, lastSaved: current);
  }

  Future<Result<void, Failure>> _save(
    final String tryonId, {
    required final TryonFeedback? lastSaved,
  }) async {
    state = state.copyWith(saving: {...state.saving, tryonId});

    // Captured before the await: `this.ref` follows the notifier into its next
    // build, so only this one goes unmounted when the auth reset rebuilds it.
    final ref = this.ref;
    final result = await ref.read(rateTryonUseCaseProvider)(
      RateTryonParams(tryonId: tryonId, feedback: state.feedback[tryonId]),
    );
    if (!ref.mounted) return result;

    if (result.isFailure) _show(tryonId, lastSaved);
    state = state.copyWith(saving: {...state.saving}..remove(tryonId));
    return result;
  }

  void _show(final String tryonId, final TryonFeedback? feedback) {
    final next = {...state.feedback};
    if (feedback == null) {
      next.remove(tryonId);
    } else {
      next[tryonId] = feedback;
    }
    state = state.copyWith(feedback: next);
  }
}
