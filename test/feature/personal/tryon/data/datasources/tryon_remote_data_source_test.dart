import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

import '../../../../../support/fake_functions_client.dart';

const _request = TryonFunctionRequest(
  generationId: 'g1',
  mode: TryonMode.image,
  engine: TryonEngine.standard,
);

void main() {
  TryonRemoteDataSource dataSource(final FunctionException error) =>
      TryonRemoteDataSource(
        FakeSupabaseClient(FakeFunctionsClient(error: error)),
      );

  TryonRemoteDataSource answering(final Object? data) => TryonRemoteDataSource(
    FakeSupabaseClient(FakeFunctionsClient(data: data)),
  );

  test('decodes the generated image and usage', () async {
    final response = await answering({
      'imageUrl': 'https://cdn/r.png',
      'usage': {
        'user_id': 'u1',
        'usage_date': '2026-10-11',
        'tryon_count': 1,
        'chat_count': 0,
        'video_count': 0,
      },
    }).tryon(_request);

    expect(response.imageUrl, 'https://cdn/r.png');
    expect(response.videoUrl, isNull);
    expect(response.usage?.tryonCount, 1);
  });

  test('a malformed response surfaces as a ServerException', () async {
    await expectLater(
      answering({'imageUrl': 42}).tryon(_request),
      throwsA(isA<ServerException>()),
    );
  });

  test('a non-object response surfaces as a ServerException', () async {
    await expectLater(
      answering('oops').tryon(_request),
      throwsA(isA<ServerException>()),
    );
  });

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
