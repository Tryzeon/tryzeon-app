import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:typed_result/typed_result.dart';

class EmailOtpBottomSheet extends HookConsumerWidget {
  const EmailOtpBottomSheet({super.key, required this.userType});

  final UserType userType;

  static Future<void> show(final BuildContext context, final UserType userType) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (final context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EmailOtpBottomSheet(userType: userType),
      ),
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

      FocusScope.of(context).unfocus();
      isLoading.value = true;

      final sendEmailOtpUseCase = ref.read(sendEmailOtpUseCaseProvider);
      final result = await sendEmailOtpUseCase(email: email, userType: userType);

      if (context.mounted) {
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
    }

    Future<void> handleVerifyEmailOtp() async {
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

      if (context.mounted) {
        isLoading.value = false;
        if (result.isSuccess) {
          Navigator.of(context).pop();
          context.go(AppRoutes.homeForUserType(userType));
        } else {
          TopNotification.show(
            context,
            message: result.getError()?.displayMessage(context) ?? '驗證碼錯誤',
          );
        }
      }
    }

    Widget buildInput({
      required final TextEditingController controller,
      required final String hint,
      required final String? Function(String?) validator,
      final bool isNumber = false,
      final void Function(String)? onSubmitted,
    }) {
      return TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        style: textTheme.bodyLarge,
        decoration: InputDecoration(hintText: hint),
      );
    }

    Widget buildButton(final String text, final VoidCallback onTap) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading.value ? null : onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          child: isLoading.value
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(text),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: isOtpSent.value
            ? Form(
                key: otpFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('輸入驗證碼', style: textTheme.headlineLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '已發送至 ${emailController.text}',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildInput(
                      controller: tokenController,
                      hint: '6位數驗證碼',
                      isNumber: true,
                      validator: AppValidators.validateOtp,
                      onSubmitted: (_) => handleVerifyEmailOtp(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildButton('驗證並登入', handleVerifyEmailOtp),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: TextButton(
                        onPressed: (resendCountdown.value > 0 || isLoading.value)
                            ? null
                            : () => handleSendEmailOtp(isResend: true),
                        child: Text(
                          isLoading.value && resendCountdown.value <= 0
                              ? '重新發送中...'
                              : resendCountdown.value > 0
                              ? '重新發送 (${resendCountdown.value}s)'
                              : '重新發送驗證碼',
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Form(
                key: emailFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('使用 Email 登入', style: textTheme.headlineLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '我們將發送驗證碼至您的信箱',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildInput(
                      controller: emailController,
                      hint: 'name@example.com',
                      validator: AppValidators.validateEmail,
                      onSubmitted: (_) => handleSendEmailOtp(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildButton('發送驗證碼', handleSendEmailOtp),
                  ],
                ),
              ),
      ),
    );
  }
}
