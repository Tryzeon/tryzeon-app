import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/loading_overlay.dart';
import 'package:tryzeon/core/presentation/widgets/settings_list_tile.dart';
import 'package:tryzeon/core/presentation/widgets/settings_section.dart';
import 'package:tryzeon/core/presentation/widgets/settings_sliver_app_bar.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/presentation/widgets/version_info.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/presentation/providers/personal_settings_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonalSettingsPage extends HookConsumerWidget {
  const PersonalSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = ref.watch(personalSettingsControllerProvider.notifier);

    // Listen for global errors/state changes
    ref.listen(personalSettingsControllerProvider, (final previous, final next) {
      if (next is AsyncError) {
        TopNotification.show(
          context,
          message: (next.error as dynamic).displayMessage(context),
          type: NotificationType.error,
        );
      }
    });

    Future<void> handleSignOut() async {
      final result = await showOkCancelAlertDialog(
        context: context,
        title: '登出',
        message: '你確定要登出嗎？',
        okLabel: '登出',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );
      if (result != OkCancelResult.ok) return;

      await controller.signOut();
    }

    Future<void> switchToStore() async {
      final result = await showOkCancelAlertDialog(
        context: context,
        title: '切換帳號',
        message: '你確定要切換到店家版帳號嗎？',
        okLabel: '確定',
        cancelLabel: '取消',
      );
      if (result != OkCancelResult.ok) return;

      await controller.switchToStore();
      if (!context.mounted) return;

      context.go('/store/home');
    }

    Future<void> handleDeleteAccount() async {
      final dialogResult = await showOkCancelAlertDialog(
        context: context,
        title: '刪除帳號',
        message: '此操作將永久刪除您的帳號及所有相關資料，包括個人資料、衣櫃、店家資料（如有）等，且無法復原。您確定要繼續嗎？',
        okLabel: '刪除帳號',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );
      if (dialogResult != OkCancelResult.ok) return;

      await controller.deleteAccount();
    }

    final state = ref.watch(personalSettingsControllerProvider);
    final isLoading = state.isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            const SettingsSliverAppBar(title: '設定'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    const _ProfileHeader(),
                    const SizedBox(height: 32),
                    SettingsSection(
                      title: '帳號設定',
                      children: [
                        SettingsListTile(
                          icon: Icons.tune_rounded,
                          title: '偏好設定',
                          subtitle: '管理您的個人偏好',
                          onTap: () => context.push('/personal/settings/preferences'),
                          color: colorScheme.secondary,
                        ),
                        SettingsListTile(
                          icon: Icons.card_membership_rounded,
                          title: '訂閱方案',
                          subtitle: '升級您的帳號',
                          onTap: () => context.push('/personal/settings/subscription'),
                          color: colorScheme.tertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SettingsSection(
                      title: '其他',
                      children: [
                        SettingsListTile(
                          icon: Icons.store_outlined,
                          title: '切換到店家帳號',
                          subtitle: '管理您的商店',
                          onTap: switchToStore,
                          color: colorScheme.primary,
                          hideChevron: true,
                        ),
                        SettingsListTile(
                          icon: Icons.contact_support_outlined,
                          title: '聯絡我們',
                          subtitle: '前往官方 Instagram',
                          onTap: () async {
                            final url = Uri.parse('https://www.instagram.com/tryzeon/');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SettingsSection(
                      title: '危險區域',
                      children: [
                        SettingsListTile(
                          icon: Icons.logout_rounded,
                          title: '登出',
                          onTap: handleSignOut,
                          color: colorScheme.error,
                          isDestructive: true,
                          hideChevron: true,
                        ),
                        SettingsListTile(
                          icon: Icons.delete_forever_rounded,
                          title: '刪除帳號',
                          onTap: handleDeleteAccount,
                          color: colorScheme.error,
                          isDestructive: true,
                          hideChevron: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    VersionInfo(
                      versionProvider: (final ref) => ref
                          .read(personalSettingsControllerProvider.notifier)
                          .getAppVersion(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends HookConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final avatarFileAsync = ref.watch(avatarFileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => context.push('/personal/settings/profile'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: colorScheme.surface, width: 3),
              ),
              child: ClipOval(
                child: profileAsync.when(
                  data: (final profile) {
                    if (profile == null) {
                      return Icon(Icons.person, size: 36, color: colorScheme.primary);
                    }
                    return avatarFileAsync.when(
                      data: (final file) {
                        if (file != null) {
                          return Image.file(
                            file,
                            fit: BoxFit.cover,
                            width: 70,
                            height: 70,
                          );
                        }
                        return _buildPlaceholder(colorScheme, profile.name);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (final _, final _) =>
                          _buildPlaceholder(colorScheme, profile.name),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (final _, final _) =>
                      Icon(Icons.person, size: 36, color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileAsync.maybeWhen(
                    data: (final profile) {
                      if (profile == null) return const SizedBox.shrink();
                      final email = profile.email;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: theme.textTheme.titleLarge),
                          if (email != null && email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colorScheme.outlineVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(final ColorScheme colorScheme, final String name) {
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
