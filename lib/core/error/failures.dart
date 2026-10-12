import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/daily_usage/data/mappers/daily_usage_payload.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';

sealed class Failure extends Equatable {
  const Failure([this.message]);
  final String? message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure({final String? message, this.usage}) : super(message);

  final DailyUsage? usage;

  @override
  List<Object?> get props => [message, usage];
}

class ServiceBusyFailure extends Failure {
  const ServiceBusyFailure([super.message]);
}

class UserCanceledFailure extends Failure {
  const UserCanceledFailure([super.message]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

class AvatarMissingFailure extends Failure {
  const AvatarMissingFailure([super.message]);
}

class WardrobeFullFailure extends Failure {
  const WardrobeFullFailure([super.message]);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message]);
}

Failure mapExceptionToFailure(final Object e) {
  if (e is AuthException && e.code == 'otp_expired') {
    return const AuthFailure('驗證碼錯誤或過期');
  }

  // PGRST116 = `.single()` matched no rows.
  if (e is PostgrestException && e.code == 'PGRST116') {
    return const NotFoundFailure();
  }

  // TZ001 = the wardrobe_items insert trigger rejected a full wardrobe.
  if (e is PostgrestException && e.code == 'TZ001') {
    return const WardrobeFullFailure();
  }

  if (e is FunctionException) {
    final body = e.details;
    if (body is Map) {
      final Failure? coded = switch (body['code']) {
        AppConstants.functionErrorServiceBusy => const ServiceBusyFailure(),
        AppConstants.functionErrorNoAvatar => const AvatarMissingFailure(),
        AppConstants.functionErrorAiGenerationFailed => const ServerFailure(
          'AI 無法辨識圖片，請換一張試試',
        ),
        AppConstants.functionErrorRateLimitExceeded => RateLimitFailure(
          usage: tryParseDailyUsagePayload(body['usage']),
        ),
        _ => null,
      };
      if (coded != null) return coded;
    }

    // A 401 never reaches our handler — the platform rejects the JWT first, so
    // there is no code of ours to read and the status is all we get.
    if (e.status == 401) return const AuthFailure('驗證失敗，請重新登入');

    // A 429 with no code of ours was imposed before our handler ran, so it
    // carries no usage either — ours always sends the two together.
    if (e.status == 429) return const RateLimitFailure();
  }

  return switch (e) {
    ServerException(message: final msg) => ServerFailure(msg),
    UnauthenticatedException(message: final msg) => AuthFailure(msg),
    UserCanceledException(message: final msg) => UserCanceledFailure(msg),
    NotFoundException(message: final msg) => NotFoundFailure(msg),
    CacheDecodeException(message: final msg) => UnknownFailure(msg),

    PostgrestException() => const ServerFailure(),
    StorageException() => const ServerFailure(),
    FunctionException() => const ServerFailure(),
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

    _ => const UnknownFailure(),
  };
}
