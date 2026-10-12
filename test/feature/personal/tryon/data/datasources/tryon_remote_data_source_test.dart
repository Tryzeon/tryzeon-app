import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';

class _ThrowingFunctions implements FunctionsClient {
  _ThrowingFunctions(this.error);

  final FunctionException error;

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      Future<FunctionResponse>.error(error);
}

class _FakeSupabase implements SupabaseClient {
  _FakeSupabase(this.functions);

  @override
  final FunctionsClient functions;

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

const _request = TryonFunctionRequest(
  generationId: 'g1',
  garments: [],
  mode: 'scene',
  isVideo: false,
  engine: 'standard',
);

void main() {
  TryonRemoteDataSource dataSource(final FunctionException error) =>
      TryonRemoteDataSource(_FakeSupabase(_ThrowingFunctions(error)));

  test('a rate limit carries the usage snapshot it was sent with', () async {
    final call = dataSource(
      const FunctionException(
        status: 429,
        details: {
          'code': 'RATE_LIMIT_EXCEEDED',
          'usage': {
            'user_id': 'u1',
            'usage_date': '2026-10-11',
            'tryon_count': 3,
            'chat_count': 0,
            'video_count': 0,
          },
        },
      ),
    ).tryon(_request);

    await expectLater(
      call,
      throwsA(
        isA<RateLimitException>().having(
          (final e) => e.usage,
          'usage',
          DailyUsage(
            userId: 'u1',
            usageDate: DateTime(2026, 10, 11),
            tryonCount: 3,
            chatCount: 0,
            videoCount: 0,
          ),
        ),
      ),
    );
  });

  test('a malformed usage snapshot still surfaces the rate limit', () async {
    await expectLater(
      dataSource(
        const FunctionException(
          status: 429,
          details: {'code': 'RATE_LIMIT_EXCEEDED', 'usage': 'not a map'},
        ),
      ).tryon(_request),
      throwsA(
        isA<RateLimitException>().having((final e) => e.usage, 'usage', isNull),
      ),
    );
  });

  test('any other function error is rethrown untouched', () async {
    const error = FunctionException(
      status: 503,
      details: {'code': 'SERVICE_BUSY'},
    );

    await expectLater(dataSource(error).tryon(_request), throwsA(same(error)));
  });
}
