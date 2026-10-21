import 'package:flutter/foundation.dart';

enum AppEnvironment {
  production,
  local;

  static final AppEnvironment current = resolveAppEnvironment(
    const String.fromEnvironment('APP_ENV'),
    isRelease: kReleaseMode,
  );
}

AppEnvironment resolveAppEnvironment(
  final String value, {
  required final bool isRelease,
}) {
  final environment = switch (value) {
    '' => AppEnvironment.production,
    'local' => AppEnvironment.local,
    _ => throw ArgumentError.value(
      value,
      'APP_ENV',
      'must be empty (production) or local',
    ),
  };
  if (isRelease && environment == AppEnvironment.local) {
    throw StateError('APP_ENV=local is only allowed in debug builds');
  }
  return environment;
}
