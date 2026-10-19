import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/errors/api_error_code.dart';
import 'package:tryzeon/core/error/failure_from_error.dart';
import 'package:tryzeon/core/error/failures.dart';

/// Translates SDK and transport errors every datasource can raise. An error
/// only one feature understands (a trigger's SQLSTATE, an endpoint-specific
/// code) is turned into that feature's [AppException] by its datasource first.
Failure mapExceptionToFailure(final Object e) => switch (e) {
  // PGRST116 = `.single()` matched no rows.
  PostgrestException(code: 'PGRST116') => const NotFoundFailure(),
  PostgrestException() => const ServerFailure(),
  StorageException() => const ServerFailure(),
  FunctionException() => _functionFailure(e),
  AuthRetryableFetchException() => const NetworkFailure(),
  AuthException() => const AuthFailure(),

  SocketException() => const NetworkFailure(),
  // Client-side deadline: a half-open socket that never delivers bytes,
  // EOF or an error.
  TimeoutException() => const TimeoutFailure(),
  // http wraps transport-level failures escaping Supabase in ClientException.
  ClientException() => const NetworkFailure(),
  HandshakeException() => const NetworkFailure(),
  HttpException() => const ServerFailure(),
  TlsException() => const ServerFailure(),

  _ => failureFromError(e),
};

Failure _functionFailure(final FunctionException e) {
  final details = e.details;
  final code = details is Map ? details['code'] : null;
  return switch (code) {
    ApiErrorCode.serviceBusy => const ServiceBusyFailure(),
    ApiErrorCode.rateLimitExceeded => const RateLimitFailure(),
    // A 401 never reaches our handler — the platform rejects the JWT first, so
    // there is no code of ours to read and the status is all we get.
    _ when e.status == 401 => const AuthFailure('驗證失敗，請重新登入'),
    // A 429 with no code of ours was imposed before our handler ran.
    _ when e.status == 429 => const RateLimitFailure(),
    _ => const ServerFailure(),
  };
}
