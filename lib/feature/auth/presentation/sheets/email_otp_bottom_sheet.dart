import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/loading_button.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:typed_result/typed_result.dart';

class EmailOtpBottomSheet extends HookConsumerWidget {
  const EmailOtpBottomSheet({super.key, required this.userType});

  final UserType userType;

  static Future<void> show(
    final BuildContext context,
    final UserType userType,
  ) {
    return showAppSheet<void>(
      context: context,
      builder: (final _) => EmailOtpBottomSheet(userType: userType),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final emailController = useTextEditingController();
    final tokenController = useTextEditingController();
    final emailFormKey = useMemoized(GlobalKey<FormState>.new);
    final otpFormKey = useMemoized(GlobalKey<FormState>.new);
    final isLoading = useState(false);
    final isOtpSent = useState(false);
    final resendCountdown = useState(0);

    useEffect(() {
      if (resendCountdown.value <= 0) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (final t) {
        if (resendCountdown.value > 0) {
          resendCountdown.value--;
        } else {
          t.cancel();
        }
      });
      return timer.cancel;
    }, [resendCountdown.value]);

    Future<void> handleSendEmailOtp({final bool isResend = false}) async {
      if (!isResend && !(emailFormKey.currentState?.validate() ?? false)) {
        return;
      }
      final email = emailController.text.trim();

      isLoading.value = true;

      final sendEmailOtpUseCase = ref.read(sendEmailOtpUseCaseProvider);
      final result = await sendEmailOtpUseCase(
        email: email,
        userType: userType,
      );

      if (!context.mounted) return;
      isLoading.value = false;
      if (result.isSuccess) {
        isOtpSent.value = true;
        tokenController.clear();
        resendCountdown.value = AppConstants.otpResendCountdownSeconds;
      } else {
        TopNotification.show(
          context,
          message: result.getError()?.displayMessage(context) ?? '發送失敗，請稍後再試',
        );
      }
    }

    Future<void> handleVerifyEmailOtp() async {
      if (isLoading.value) return;
      if (!(otpFormKey.currentState?.validate() ?? false)) {
        return;
      }
      final email = emailController.text.trim();
      final token = tokenController.text.trim();

      FocusScope.of(context).unfocus();
      isLoading.value = true;

      final verifyEmailOtpUseCase = ref.read(verifyEmailOtpUseCaseProvider);
      final result = await verifyEmailOtpUseCase(
        email: email,
        token: token,
        userType: userType,
      );

      if (!context.mounted) return;
      isLoading.value = false;
      if (result.isSuccess) {
        Navigator.of(context).pop();
      } else {
        TopNotification.show(
          context,
          message: result.getError()?.displayMessage(context) ?? '驗證碼錯誤',
        );
      }
    }

    void editEmail() {
      isOtpSent.value = false;
      tokenController.clear();
    }

    Widget buildHint(final String text) => Text(
      text,
      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
    );

    Widget buildEmailStep() {
      return Form(
        key: emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHint('我們將發送驗證碼至您的信箱'),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              validator: AppValidators.validateEmail,
              onFieldSubmitted: (final _) => handleSendEmailOtp(),
              style: textTheme.bodyLarge,
              decoration: const InputDecoration(hintText: 'name@example.com'),
            ),
          ],
        ),
      );
    }

    Widget buildOtpStep() {
      final resendLabel = isLoading.value && resendCountdown.value <= 0
          ? '重新發送中...'
          : resendCountdown.value > 0
          ? '重新發送 (${resendCountdown.value}s)'
          : '重新發送驗證碼';

      return Form(
        key: otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: buildHint('已發送至 ${emailController.text.trim()}'),
                ),
                TextButton(onPressed: editEmail, child: const Text('更改')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: tokenController,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AppConstants.otpCodeLength),
              ],
              textInputAction: TextInputAction.done,
              validator: AppValidators.validateOtp,
              onChanged: (final value) {
                if (value.length == AppConstants.otpCodeLength) {
                  handleVerifyEmailOtp();
                }
              },
              onFieldSubmitted: (final _) => handleVerifyEmailOtp(),
              style: textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: '${AppConstants.otpCodeLength} 位數驗證碼',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: (resendCountdown.value > 0 || isLoading.value)
                    ? null
                    : () => handleSendEmailOtp(isResend: true),
                child: Text(resendLabel),
              ),
            ),
          ],
        ),
      );
    }

    return AppSheet(
      title: isOtpSent.value ? '輸入驗證碼' : '使用 Email 登入',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: isOtpSent.value ? buildOtpStep() : buildEmailStep(),
      ),
      footer: LoadingButton.filled(
        isLoading: isLoading.value,
        onPressed: isOtpSent.value ? handleVerifyEmailOtp : handleSendEmailOtp,
        child: Text(isOtpSent.value ? '驗證並登入' : '發送驗證碼'),
      ),
    );
  }
}
