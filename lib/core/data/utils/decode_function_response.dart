import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

/// A body the client cannot decode is the server breaking its contract, so it
/// surfaces as a [ServerException] instead of a raw type error that would map
/// to an unknown failure. Pair with `@JsonSerializable(checked: true)`.
T decodeFunctionResponse<T>(
  final Object? data,
  final T Function(Map<String, dynamic> json) fromJson,
) {
  if (data is! Map) {
    AppLogger.warning('Function response is not an object: $data');
    throw const ServerException();
  }
  try {
    return fromJson(Map<String, dynamic>.from(data));
  } on CheckedFromJsonException catch (e, stackTrace) {
    AppLogger.warning('Malformed function response', e, stackTrace);
    throw const ServerException();
  }
}
