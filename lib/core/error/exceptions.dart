import 'package:tryzeon/core/error/failures.dart';

/// Thrown inside the data layer. Each exception names the [Failure] it becomes,
/// so a feature can add its own pair without touching core.
abstract class AppException implements Exception {
  const AppException([this.message]);
  final String? message;

  Failure toFailure();

  @override
  String toString() => message ?? runtimeType.toString();
}

class ServerException extends AppException {
  const ServerException([super.message]);

  @override
  Failure toFailure() => ServerFailure(message);
}

class UnauthenticatedException extends AppException {
  const UnauthenticatedException([super.message]);

  @override
  Failure toFailure() => AuthFailure(message);
}

class UserCanceledException extends AppException {
  const UserCanceledException([super.message]);

  @override
  Failure toFailure() => UserCanceledFailure(message);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message]);

  @override
  Failure toFailure() => NotFoundFailure(message);
}

class CacheDecodeException extends AppException {
  const CacheDecodeException([super.message]);

  @override
  Failure toFailure() => UnknownFailure(message);
}
