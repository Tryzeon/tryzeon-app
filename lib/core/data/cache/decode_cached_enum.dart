import 'package:tryzeon/core/error/exceptions.dart';

T decodeCachedEnum<T>(
  final String raw,
  final T? Function(String?) parse, {
  required final String field,
}) {
  final value = parse(raw);
  if (value == null) {
    throw CacheDecodeException('Cached $field holds an unknown value: $raw');
  }
  return value;
}

T? decodeCachedEnumOrNull<T>(
  final String? raw,
  final T? Function(String?) parse, {
  required final String field,
}) => raw == null ? null : decodeCachedEnum(raw, parse, field: field);

List<T>? decodeCachedEnumList<T>(
  final List<String>? raw,
  final T? Function(String?) parse, {
  required final String field,
}) => raw?.map((final e) => decodeCachedEnum(e, parse, field: field)).toList();
