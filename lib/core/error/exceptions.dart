/// Base class for all application exceptions
abstract class AppException implements Exception {
  const AppException([this.message]);
  final String? message;

  @override
  String toString() => message ?? runtimeType.toString();
}

/// Thrown when the server returns an error (e.g., 500 Internal Server Error)
class ServerException extends AppException {
  const ServerException([super.message, this.statusCode]);
  final int? statusCode;
}

/// Thrown when the user is not authenticated (not logged in or token expired)
class UnauthenticatedException extends AppException {
  const UnauthenticatedException([super.message]);
}
