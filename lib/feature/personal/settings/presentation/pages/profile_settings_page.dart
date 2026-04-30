import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class PersonalProfileSettingsPage extends HookConsumerWidget {
  const PersonalProfileSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('編輯個人資料', style: textTheme.headlineMedium),
                        Text('更新您的個人資訊', style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: profileAsync.when(
                data: (final profile) {
                  if (profile == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _PersonalProfileForm(profile: profile);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (final error, final stack) => ErrorView(
                  message: error.displayMessage(context),
                  onRetry: () => refreshUserProfile(ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalProfileForm extends HookConsumerWidget {
  const _PersonalProfileForm({required this.profile});

  final UserProfile profile;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameController = useTextEditingController(text: profile.name);
    final isLoading = useState(false);
    final userName = useValueListenable(nameController).text;
    final hasChanges = userName.trim() != profile.name;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> updateProfile() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      final updateUseCase = ref.read(updateUserProfileUseCaseProvider);
      final result = await updateUseCase(name: nameController.text.trim());

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        TopNotification.show(context, message: '個人資料已更新', type: NotificationType.success);

        if (context.mounted) Navigator.pop(context);

        Future.delayed(const Duration(milliseconds: 100), () {
          ref.invalidate(userProfileProvider);
        });
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
          type: NotificationType.error,
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: AppRadius.cardAll,
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('基本資料', style: textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '姓名',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  validator: AppValidators.validateUserName,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading.value || !hasChanges ? null : updateProfile,
                    child: isLoading.value
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, size: 24),
                              SizedBox(width: AppSpacing.sm),
                              Text('儲存'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
