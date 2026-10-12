import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/daily_usage/data/exceptions/usage_limit_exception.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/failures/usage_limit_failure.dart';

void main() {
  final usage = DailyUsage(
    userId: 'u1',
    usageDate: DateTime(2026, 10, 11),
    tryonCount: 3,
    chatCount: 0,
    videoCount: 0,
  );

  test('carries its usage into the failure', () {
    expect(
      mapExceptionToFailure(UsageLimitException(usage: usage)),
      UsageLimitFailure(usage: usage),
    );
  });

  test('is still a rate limit to code that only cares about the limit', () {
    expect(UsageLimitFailure(usage: usage), isA<RateLimitFailure>());
  });
}
