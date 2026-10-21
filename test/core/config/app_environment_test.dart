import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/config/app_environment.dart';

void main() {
  test('empty value resolves to production', () {
    expect(
      resolveAppEnvironment('', isRelease: true),
      AppEnvironment.production,
    );
  });

  test('local resolves to local in debug', () {
    expect(
      resolveAppEnvironment('local', isRelease: false),
      AppEnvironment.local,
    );
  });

  test('local is rejected in release builds', () {
    expect(
      () => resolveAppEnvironment('local', isRelease: true),
      throwsStateError,
    );
  });

  test('unknown value is rejected and lists allowed values', () {
    expect(
      () => resolveAppEnvironment('staging', isRelease: false),
      throwsA(
        isA<ArgumentError>().having(
          (final e) => e.message,
          'message',
          contains('local'),
        ),
      ),
    );
  });

  test('value is case-sensitive', () {
    expect(
      () => resolveAppEnvironment('Local', isRelease: false),
      throwsArgumentError,
    );
  });
}
