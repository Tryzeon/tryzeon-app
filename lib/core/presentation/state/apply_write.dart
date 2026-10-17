import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

/// Lets the notifier that owns an aggregate apply its own writes: the written
/// value is merged into the state instead of refetching. Unless the state is
/// settled data (a rebuild in flight would overwrite the merge), or when
/// [merge] returns null, it rebuilds from the repository, whose cache the
/// write already updated.
mixin ApplyWrite<T> on AnyNotifier<AsyncValue<T>, T> {
  Future<Result<R, Failure>> applyWrite<R>(
    final Future<Result<R, Failure>> Function() write, {
    required final T? Function(T current, R written) merge,
  }) async {
    final ref = this.ref;
    final link = ref.keepAlive();
    try {
      final result = await write();
      if (!ref.mounted) return result;

      if (result case Ok(:final value)) {
        final merged = switch (state) {
          AsyncData(value: final current, isLoading: false) => merge(
            current,
            value,
          ),
          _ => null,
        };
        if (merged != null) {
          state = AsyncData(merged);
        } else {
          ref.invalidateSelf();
        }
      }
      return result;
    } finally {
      link.close();
    }
  }
}
