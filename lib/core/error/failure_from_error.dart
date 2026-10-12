import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';

/// For errors caught outside the data layer, where SDK exceptions never reach:
/// a [Failure] a provider rethrew passes through unchanged.
Failure failureFromError(final Object error) => switch (error) {
  Failure() => error,
  AppException() => error.toFailure(),
  _ => const UnknownFailure(),
};
