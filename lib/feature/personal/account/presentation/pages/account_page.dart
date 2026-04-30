import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/loading_overlay.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/presentation/providers/personal_settings_controller.dart';

class AccountPage extends HookConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(personalSettingsControllerProvider);

    ref.listen(personalSettingsControllerProvider, (final previous, final next) {
      if (next is AsyncError) {
        TopNotification.show(
          context,
          message: next.error.displayMessage(context),
          type: NotificationType.error,
        );
      }
    });

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: AppSpacing.xxl,
                        height: AppSpacing.xxl,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(AppRadius.icon),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: colorScheme.onPrimary,
                          size: AppSpacing.lg,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('帳號中心', style: theme.textTheme.headlineMedium),
                            Text('管理個人帳戶', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push(AppRoutes.personalSettings),
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: '設定',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    const _MyProfileHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    const _MySectionHeader(title: '帳號中心'),
                    const SizedBox(height: AppSpacing.md),
                    _MyActionGroup(
                      children: [
                        ListTile(
                          onTap: () =>
                              context.push(AppRoutes.personalSettingsBodyMeasurements),
                          leading: Container(
                            width: AppSpacing.xxl,
                            height: AppSpacing.xxl,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.icon),
                            ),
                            child: Icon(
                              Icons.straighten_rounded,
                              color: colorScheme.primary,
                              size: AppSpacing.lg,
                            ),
                          ),
                          title: const Text('身形資料'),
                          subtitle: const Text('管理您的身形量測數據'),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: AppSpacing.md,
                          ),
                        ),
                        ListTile(
                          onTap: () => context.push(AppRoutes.personalSubscription),
                          leading: Container(
                            width: AppSpacing.xxl,
                            height: AppSpacing.xxl,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.icon),
                            ),
                            child: Icon(
                              Icons.workspace_premium_outlined,
                              color: colorScheme.primary,
                              size: AppSpacing.lg,
                            ),
                          ),
                          title: const Text('訂閱方案'),
                          subtitle: const Text('查看目前方案與升級選項'),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: AppSpacing.md,
                          ),
                        ),
                      ],
                    ),
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

class _MyProfileHeader extends HookConsumerWidget {
  const _MyProfileHeader();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 取得資料狀態
    final profileAsync = ref.watch(userProfileProvider);
    final avatarFileAsync = ref.watch(avatarFileProvider);
    final user = ref.watch(currentUserProvider);

    // 解析資料內容
    final profile = profileAsync.value;
    final avatarFile = avatarFileAsync.value;
    final email = user?.email ?? user?.userMetadata?['email'] as String?;

    // 網路狀態判定
    final isProfileLoading = profileAsync.isLoading && !profileAsync.hasValue;
    final isAvatarLoading = avatarFileAsync.isLoading && !avatarFileAsync.hasValue;
    final hasProfileError = profileAsync.hasError;

    // UI Helper: 頭像區域
    Widget buildAvatar() {
      if (isProfileLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (hasProfileError || profile == null) {
        return Icon(Icons.person, size: AppSpacing.xl, color: colorScheme.primary);
      }
      if (isAvatarLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (avatarFile != null) {
        return Image.file(
          avatarFile,
          fit: BoxFit.cover,
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
        );
      }
      return Container(
        color: colorScheme.surfaceContainer,
        child: Icon(
          Icons.person,
          size: AppSpacing.xl,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // UI Helper: 基本資訊區域
    Widget buildInfo() {
      if (isProfileLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (hasProfileError) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('載入個人資料失敗', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('請稍後再試', style: theme.textTheme.bodyMedium),
          ],
        );
      }
      if (profile == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('尚未建立個人資料', style: theme.textTheme.titleMedium)],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(profile.name, style: theme.textTheme.titleLarge),
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              email,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainer,
              ),
              child: ClipOval(child: buildAvatar()),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: buildInfo()),
          ],
        ),
      ),
    );
  }
}

class _MySectionHeader extends StatelessWidget {
  const _MySectionHeader({required this.title});

  final String title;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}

class _MyActionGroup extends StatelessWidget {
  const _MyActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(final BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children.asMap().entries.map((final entry) {
          final index = entry.key;
          final child = entry.value;
          return Column(children: [if (index > 0) const Divider(), child]);
        }).toList(),
      ),
    );
  }
}
