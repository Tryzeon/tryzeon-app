import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_remote_datasource.dart';

import '../../../../support/fake_supabase_http.dart';

void main() {
  Future<void> verifyAnswering(final String errorCode) => AuthRemoteDataSource(
    supabaseAnswering(403, {
      'code': 403,
      'error_code': errorCode,
      'msg': 'Token has expired or is invalid',
    }),
  ).verifyEmailOTP(email: 'a@b.co', token: '123456');

  test('an expired code surfaces with copy the user can act on', () async {
    await expectLater(
      verifyAnswering('otp_expired'),
      throwsA(
        isA<UnauthenticatedException>().having(
          (final e) => e.message,
          'message',
          '驗證碼錯誤或過期',
        ),
      ),
    );
  });

  test('any other auth error is rethrown untouched', () async {
    await expectLater(
      verifyAnswering('over_email_send_rate_limit'),
      throwsA(isA<AuthException>()),
    );
  });
}
