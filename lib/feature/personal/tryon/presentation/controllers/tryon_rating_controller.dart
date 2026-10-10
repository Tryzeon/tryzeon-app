import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_rating.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/rate_tryon.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'tryon_rating_controller.freezed.dart';
part 'tryon_rating_controller.g.dart';

@freezed
sealed class TryonRatingState with _$TryonRatingState {
  const factory TryonRatingState({
    @Default(<String, TryonRating>{}) final Map<String, TryonRating> ratings,
    @Default(<String>{}) final Set<String> saving,
  }) = _TryonRatingState;
}

@Riverpod(keepAlive: true)
class TryonRatingController extends _$TryonRatingController {
  @override
  TryonRatingState build() {
    ref.watch(isAuthenticatedProvider);
    return const TryonRatingState();
  }

  /// Ignores a tap on a try-on whose last rating is still saving: responses
  /// could land out of order and leave the server disagreeing with the screen.
  Future<Result<void, Failure>> toggle(
    final String tryonId,
    final TryonRating tapped,
  ) async {
    if (state.saving.contains(tryonId)) return const Ok(null);

    final previous = state.ratings[tryonId];
    final next = previous == tapped ? null : tapped;
    state = state.copyWith(
      ratings: _withRating(state.ratings, tryonId, next),
      saving: {...state.saving, tryonId},
    );

    // Captured before the await: `this.ref` follows the notifier into its next
    // build, so only this one goes unmounted when the auth reset rebuilds it.
    final ref = this.ref;
    final result = await ref.read(rateTryonUseCaseProvider)(
      RateTryonParams(tryonId: tryonId, rating: next),
    );
    if (!ref.mounted) return result;

    state = state.copyWith(
      ratings: result.isSuccess
          ? state.ratings
          : _withRating(state.ratings, tryonId, previous),
      saving: {...state.saving}..remove(tryonId),
    );
    return result;
  }

  static Map<String, TryonRating> _withRating(
    final Map<String, TryonRating> ratings,
    final String tryonId,
    final TryonRating? rating,
  ) {
    final next = {...ratings};
    if (rating == null) {
      next.remove(tryonId);
    } else {
      next[tryonId] = rating;
    }
    return next;
  }
}
