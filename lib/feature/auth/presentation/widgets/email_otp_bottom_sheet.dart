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
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (final context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EmailOtpBottomSheet(userType: userType),
      ),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final emailController = useTextEditingController();
    final tokenController = useTextEditingController();
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
    }, [resendCountdown.value > 0]);

    bool isValidEmail(final String email) {
      return RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%\&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(email);
    }

    Future<void> handleSendEmailOtp({final bool isResend = false}) async {
      final email = emailController.text.trim();
      if (email.isEmpty || !isValidEmail(email)) {
        TopNotification.show(
          context,
          message: '請輸入有效的電子郵件',
          type: NotificationType.error,
        );
        return;
      }

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
          TopNotification.show(
            context,
            message: isResend ? '驗證碼已重新發送' : '驗證碼已發送，請檢查您的信箱',
            type: NotificationType.success,
          );
        } else {
          TopNotification.show(
            context,
            message: result.getError()?.displayMessage(context) ?? '發送失敗，請稍後再試',
            type: NotificationType.error,
          );
        }
      }
    }

    Future<void> handleVerifyEmailOtp() async {
      final email = emailController.text.trim();
      final token = tokenController.text.trim();

      if (token.isEmpty) {
        TopNotification.show(context, message: '請輸入驗證碼', type: NotificationType.error);
        return;
      }

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
          context.pop();
          context.go(AppRoutes.homeForUserType(userType));
        } else {
          TopNotification.show(
            context,
            message: result.getError()?.displayMessage(context) ?? '驗證碼錯誤',
            type: NotificationType.error,
          );
        }
      }
    }

    Widget buildInput({
      required final TextEditingController controller,
      required final String hint,
      final bool isNumber = false,
      final void Function(String)? onSubmitted,
    }) {
      return TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: onSubmitted,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: const OutlineInputBorder(
            borderRadius: AppRadius.inputAll,
            borderSide: BorderSide(color: AppColors.outline, width: 1.5),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.inputAll,
            borderSide: BorderSide(color: AppColors.outline, width: 1.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.inputAll,
            borderSide: BorderSide(color: AppColors.onSurface, width: 1.5),
          ),
        ),
      );
    }

    Widget buildButton(final String text, final VoidCallback onTap) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading.value ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
          ),
          child: isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(
                  text,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isOtpSent.value
              ? Column(
                  key: const ValueKey('otp'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '輸入驗證碼',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '已發送至 ${emailController.text}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildInput(
                      controller: tokenController,
                      hint: '6位數驗證碼',
                      isNumber: true,
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: (resendCountdown.value > 0 || isLoading.value)
                                ? AppColors.onSurfaceVariant
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('email'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用 Email 登入',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '我們將發送驗證碼至您的信箱',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    buildInput(
                      controller: emailController,
                      hint: 'name@example.com',
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
