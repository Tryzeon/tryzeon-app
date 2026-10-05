import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/usecases/send_email_otp.dart';
import 'package:tryzeon/feature/auth/domain/usecases/verify_email_otp.dart';
import 'package:tryzeon/feature/auth/presentation/sheets/email_otp_bottom_sheet.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../support/sheet_test_host.dart';

class _FakeSendEmailOtp implements SendEmailOtp {
  final emails = <String>[];

  @override
  Future<Result<void, Failure>> call({
    required final String email,
    required final UserType userType,
  }) async {
    emails.add(email);
    return const Ok(null);
  }
}

class _FakeVerifyEmailOtp implements VerifyEmailOtp {
  final tokens = <String>[];

  @override
  Future<Result<void, Failure>> call({
    required final String email,
    required final String token,
    required final UserType userType,
  }) async {
    tokens.add(token);
    return const Ok(null);
  }
}

void main() {
  const email = 'eric@tryzeon.com';
  late _FakeSendEmailOtp send;
  late _FakeVerifyEmailOtp verify;

  Future<void> open(final WidgetTester tester) {
    send = _FakeSendEmailOtp();
    verify = _FakeVerifyEmailOtp();
    return openSheet<void>(
      tester,
      (final context) => EmailOtpBottomSheet.show(context, UserType.personal),
      overrides: [
        sendEmailOtpUseCaseProvider.overrideWithValue(send),
        verifyEmailOtpUseCaseProvider.overrideWithValue(verify),
      ],
    );
  }

  bool fieldHasFocus(final WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

  Future<void> sendCode(final WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), email);
    await tester.tap(find.text('發送驗證碼'));
    await settle(tester);
  }

  testWidgets('focuses the email field on open', (final tester) async {
    await open(tester);

    expect(fieldHasFocus(tester), isTrue);
  });

  testWidgets('does not send a code for an invalid email', (
    final tester,
  ) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('發送驗證碼'));
    await settle(tester);

    expect(send.emails, isEmpty);
  });

  testWidgets('moves to the code step with the code field focused', (
    final tester,
  ) async {
    await open(tester);

    await sendCode(tester);

    expect(send.emails, [email]);
    expect(find.text('已發送至 $email'), findsOneWidget);
    expect(fieldHasFocus(tester), isTrue);
  });

  testWidgets('verifies as soon as six digits are typed', (final tester) async {
    await open(tester);
    await sendCode(tester);

    await tester.enterText(find.byType(TextField), '123456');
    await settle(tester);

    expect(verify.tokens, ['123456']);
    expect(find.byType(EmailOtpBottomSheet), findsNothing);
  });

  testWidgets('accepts digits only, at most six', (final tester) async {
    await open(tester);
    await sendCode(tester);

    await tester.enterText(find.byType(TextField), '12a34');
    await settle(tester);

    expect(find.text('1234'), findsOneWidget);
    expect(verify.tokens, isEmpty);
  });

  testWidgets('goes back to edit the email', (final tester) async {
    await open(tester);
    await sendCode(tester);

    await tester.tap(find.text('更改'));
    await settle(tester);

    expect(find.text('發送驗證碼'), findsOneWidget);
    expect(find.widgetWithText(TextField, email), findsOneWidget);
  });
}
