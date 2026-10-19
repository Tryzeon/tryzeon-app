import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/dtos/tryon_function_request.dart';
import 'package:tryzeon/feature/personal/tryon/data/exceptions/avatar_missing_exception.dart';
import 'package:tryzeon/feature/personal/tryon/data/exceptions/quota_exceeded_exception.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

import '../../../../../support/fake_functions_client.dart';

const _request = TryonFunctionRequest(
  generationId: 'g1',
  mode: TryonMode.image,
  engine: TryonEngine.standard,
  garments: [],
);

const _quota = {
  'tier': 'pro',
  'period': 'month',
  'resetsAt': '2026-11-04T16:00:00+00:00',
  'tryonImage': {'used': 250, 'quota': 250},
  'tryonVideo': {'used': 1, 'quota': 3},
};

void main() {
  TryonRemoteDataSource dataSource(final FunctionException error) =>
      TryonRemoteDataSource(
        FakeSupabaseClient(FakeFunctionsClient(error: error)),
      );

  TryonRemoteDataSource answering(final Object? data) => TryonRemoteDataSource(
    FakeSupabaseClient(FakeFunctionsClient(data: data)),
  );

  test('decodes the generated image', () async {
    final response = await answering({
      'imageUrl': 'https://cdn/r.png',
    }).tryon(_request);

    expect(response.imageUrl, 'https://cdn/r.png');
    expect(response.videoUrl, isNull);
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

  test('a spent quota carries the snapshot it was sent with', () async {
    final call = dataSource(
      const FunctionException(
        status: 429,
        details: {'code': 'QUOTA_EXCEEDED', 'quota': _quota},
      ),
    ).tryon(_request);

    await expectLater(
      call,
      throwsA(
        isA<QuotaExceededException>().having(
          (final e) => e.quota,
          'quota',
          UsageQuota(
            tier: AppSubscriptionTier.pro,
            period: QuotaPeriod.month,
            resetsAt: DateTime.utc(2026, 11, 4, 16),
            tryonImage: const FeatureQuota(used: 250, quota: 250),
            tryonVideo: const FeatureQuota(used: 1, quota: 3),
          ),
        ),
      ),
    );
  });

  test('a malformed quota snapshot still surfaces the spent quota', () async {
    await expectLater(
      dataSource(
        const FunctionException(
          status: 429,
          details: {'code': 'QUOTA_EXCEEDED', 'quota': 'not a map'},
        ),
      ).tryon(_request),
      throwsA(
        isA<QuotaExceededException>().having(
          (final e) => e.quota,
          'quota',
          isNull,
        ),
      ),
    );
  });

  test(
    'a fair-use rate limit is rethrown, not read as a spent quota',
    () async {
      const error = FunctionException(
        status: 429,
        details: {'code': 'RATE_LIMIT_EXCEEDED'},
      );

      await expectLater(
        dataSource(error).tryon(_request),
        throwsA(same(error)),
      );
    },
  );

  test('a bare 429 is rethrown, not read as a spent quota', () async {
    const error = FunctionException(status: 429);

    await expectLater(dataSource(error).tryon(_request), throwsA(same(error)));
  });

  test('a missing avatar surfaces as an AvatarMissingException', () async {
    await expectLater(
      dataSource(
        const FunctionException(
          status: 400,
          details: {'error': 'No model photo on file', 'code': 'NO_AVATAR'},
        ),
      ).tryon(_request),
      throwsA(isA<AvatarMissingException>()),
    );
  });

  test('a failed generation keeps its own copy', () async {
    await expectLater(
      dataSource(
        const FunctionException(
          status: 422,
          details: {'code': 'AI_GENERATION_FAILED'},
        ),
      ).tryon(_request),
      throwsA(
        isA<ServerException>().having(
          (final e) => e.message,
          'message',
          'AI 無法辨識圖片，請換一張試試',
        ),
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
