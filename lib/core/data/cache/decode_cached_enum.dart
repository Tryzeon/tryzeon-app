import 'package:tryzeon/core/error/exceptions.dart';

/// Throws rather than falling back so the caller's cache read fails and the
/// repository refetches from remote — a value the client cannot decode means
/// the cached row predates a rename and must not be trusted.
T decodeCachedEnum<T>(final String raw, final T? Function(String?) parse) {
  final value = parse(raw);
  if (value == null) {
    throw CacheDecodeException('Cached $T holds an unknown value: $raw');
  }
  return value;
}

T? decodeCachedEnumOrNull<T>(
  final String? raw,
  final T? Function(String?) parse,
) => raw == null ? null : decodeCachedEnum<T>(raw, parse);

List<T>? decodeCachedEnumList<T>(
  final List<String>? raw,
  final T? Function(String?) parse,
) => raw?.map((final e) => decodeCachedEnum(e, parse)).toList();
