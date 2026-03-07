import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';

/// Base Failure class
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

/// Maps Exceptions to Failures
Failure mapExceptionToFailure(final Object e) {
  if (e is AuthException && (e as dynamic).code == 'otp_expired') {
    return const AuthFailure('驗證碼錯誤或過期');
  }

  // Handle ClientException with SocketException escaping Supabase
  final eString = e.toString();
  if (eString.contains('SocketException') || eString.contains('ClientException')) {
    return const NetworkFailure();
  }

  return switch (e) {
    // Custom App Exceptions
    ServerException(message: final msg) => ServerFailure(msg),
    UnauthenticatedException(message: final msg) => AuthFailure(msg),

    // Supabase Exceptions
    PostgrestException() => const ServerFailure(),
    StorageException() => const ServerFailure(),
    FunctionException() => const ServerFailure(),
    AuthRetryableFetchException() => const NetworkFailure(),
    AuthException() => const AuthFailure(),

    // Network Exceptions
    SocketException() => const NetworkFailure(),
    HandshakeException() => const NetworkFailure(),
    HttpException() => const ServerFailure(),
    TlsException() => const ServerFailure(),

    // Fallback
    _ => const UnknownFailure(),
  };
}
