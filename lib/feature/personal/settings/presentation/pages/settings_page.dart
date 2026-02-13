import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/auth/presentation/pages/login_page.dart';

import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/presentation/providers/personal_settings_controller.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/pages/subscription_page.dart';
import 'package:tryzeon/feature/store/main/store_entry.dart';

import 'preferences_page.dart';
import 'profile_setting_page.dart';

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
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '登出',
        content: '你確定要登出嗎？',
        confirmText: '登出',
      );
      if (confirmed != true) return;

      await controller.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (final context) => const LoginPage()),
        (final route) => false,
      );
    }

    Future<void> switchToStore() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '切換帳號',
        content: '你確定要切換到店家版帳號嗎？',
      );
      if (confirmed != true) return;

      await controller.switchToStore();
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (final context) => const StoreEntry()),
        (final route) => false,
      );
    }

    Future<void> handleDeleteAccount() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '刪除帳號',
        content: '此操作將永久刪除您的帳號及所有相關資料，包括個人資料、衣櫃、店家資料（如有）等，且無法復原。您確定要繼續嗎？',
        confirmText: '刪除帳號',
        isDestructive: true,
      );
      if (confirmed != true) return;

      final result = await controller.deleteAccount();

      if (!context.mounted) return;

      if (result.isSuccess) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (final context) => const LoginPage()),
          (final route) => false,
        );
      }
    }

    final state = ref.watch(personalSettingsControllerProvider);
    final isLoading = state.isLoading;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      const _ProfileHeader(),
                      const SizedBox(height: 32),
                      _SettingsSection(
                        title: '帳號設定',
                        children: [
                          _SettingsTile(
                            icon: Icons.tune_rounded,
                            title: '偏好設定',
                            subtitle: '管理您的個人偏好',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (final context) => const PreferencesPage(),
                              ),
                            ),
                            color: colorScheme.secondary,
                          ),
                          _SettingsTile(
                            icon: Icons.card_membership_rounded,
                            title: '訂閱方案',
                            subtitle: '升級您的帳號',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (final context) => const SubscriptionPage(),
                              ),
                            ),
                            color: colorScheme.tertiary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SettingsSection(
                        title: '其他',
                        children: [
                          _SettingsTile(
                            icon: Icons.store_outlined,
                            title: '切換到店家帳號',
                            subtitle: '管理您的商店',
                            onTap: switchToStore,
                            color: colorScheme.primary,
                            hideChevron: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SettingsSection(
                        title: '危險區域',
                        children: [
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            title: '登出',
                            onTap: handleSignOut,
                            color: colorScheme.error,
                            isDestructive: true,
                            hideChevron: true,
                          ),
                          _SettingsTile(
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
                      const _VersionInfo(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
      ),
      title: Text(
        '設定',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (final context) => const PersonalProfileSettingsPage(),
        ),
      ),
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
                      error: (final _, final __) =>
                          _buildPlaceholder(colorScheme, profile.name),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (final _, final __) =>
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
                      final email = profile.email;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (email != null && email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((final entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 20,
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  child,
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color,
    this.isDestructive = false,
    this.hideChevron = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;
  final bool isDestructive;
  final bool hideChevron;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contentColor = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (color ?? colorScheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? colorScheme.error
                      : (color ?? colorScheme.primary),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: contentColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!hideChevron)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.outlineVariant,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionInfo extends HookConsumerWidget {
  const _VersionInfo();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final versionFuture = useMemoized(
      () => ref.read(personalSettingsControllerProvider.notifier).getAppVersion(),
    );
    final versionSnapshot = useFuture(versionFuture);

    return Center(
      child: Text(
        'Version ${versionSnapshot.data ?? '...'}',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
