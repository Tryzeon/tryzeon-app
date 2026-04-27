import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/presentation/widgets/email_otp_bottom_sheet.dart';
import 'package:tryzeon/feature/auth/presentation/widgets/identity_segmented_control.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:typed_result/typed_result.dart';

class UnifiedLoginPage extends HookConsumerWidget {
  const UnifiedLoginPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final userType = useState(UserType.personal);
    final isLoading = useState(false);

    Future<void> handleSocialLogin(final String provider) async {
      isLoading.value = true;
      final signInUseCase = ref.read(signInWithProviderUseCaseProvider);
      final result = await signInUseCase(provider: provider, userType: userType.value);

      if (!context.mounted) return;
      isLoading.value = false;

      if (result.isSuccess) {
        context.go(AppRoutes.homeForUserType(userType.value));
      } else {
        final failure = result.getError()!;
        if (failure is UserCanceledFailure) return;
        TopNotification.show(
          context,
          message: failure.displayMessage(context),
          type: NotificationType.error,
        );
      }
    }

    Widget buildSocialButton(final String provider, final VoidCallback onTap) {
      return OutlinedButton(
        onPressed: isLoading.value ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outline, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/logo/$provider.svg', height: 20, width: 20),
            const SizedBox(width: 12),
            Text(
              '使用 $provider 繼續',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onSurface,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildEmailButton() {
      return OutlinedButton(
        onPressed: isLoading.value
            ? null
            : () => EmailOtpBottomSheet.show(context, userType.value),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outline, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 20, color: AppColors.onSurface),
            const SizedBox(width: 12),
            Text(
              '使用 Email 繼續',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onSurface,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.checkroom_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Tryzeon',
                          style: Theme.of(
                            context,
                          ).textTheme.displayMedium?.copyWith(color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: IdentitySegmentedControl(
                      selectedType: userType.value,
                      onChanged: (final type) => userType.value = type,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text(
                      userType.value == UserType.personal ? '開啟您的虛擬試衣間' : '開始您的商店管理之旅',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  const Spacer(),
                  buildSocialButton('Apple', () => handleSocialLogin('Apple')),
                  const SizedBox(height: AppSpacing.md),
                  buildSocialButton('Google', () => handleSocialLogin('Google')),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.outline, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          '或',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.outline, thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  buildEmailButton(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
          if (isLoading.value)
            Container(
              color: AppColors.background.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
