import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

/// A failed refresh keeps the data already on screen and only reports the
/// failure, because many pages replace their whole content once `hasError`.
mixin PullToRefresh<T> on AnyNotifier<AsyncValue<T>, T> {
  Future<Result<void, Failure>> applyRefresh(
    final Future<Result<T, Failure>> Function() fetch,
  ) async {
    final ref = this.ref;
    final result = await fetch();
    if (!ref.mounted) return result.map((final _) {});

    switch (result) {
      case Ok(:final value):
        state = AsyncData(value);
      case Err(:final error) when !state.hasValue:
        state = AsyncError(error, StackTrace.current);
      case Err():
        break;
    }
    return result.map((final _) {});
  }
}
