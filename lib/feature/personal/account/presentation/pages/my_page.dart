import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/loading_overlay.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/presentation/providers/personal_settings_controller.dart';

class MyPage extends HookConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(personalSettingsControllerProvider);

    ref.listen(personalSettingsControllerProvider, (final previous, final next) {
      if (next is AsyncError) {
        TopNotification.show(
          context,
          message: (next.error as dynamic).displayMessage(context),
          type: NotificationType.error,
        );
      }
    });

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '帳號中心',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text('管理個人帳戶', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push(AppRoutes.personalSettings),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerLowest,
                          foregroundColor: colorScheme.onSurface,
                        ),
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    const _MyProfileHeader(),
                    const SizedBox(height: 28),
                    const _MySectionHeader(title: '帳號中心'),
                    const SizedBox(height: 12),
                    _MyActionGroup(
                      children: [
                        _MyActionTile(
                          icon: Icons.person_outline_rounded,
                          title: '編輯個人資料',
                          subtitle: '更新頭像、名稱與個人資訊',
                          onTap: () => context.push(AppRoutes.personalSettingsProfile),
                          color: colorScheme.primary,
                        ),
                        _MyActionTile(
                          icon: Icons.workspace_premium_outlined,
                          title: '訂閱方案',
                          subtitle: '查看目前方案與升級選項',
                          onTap: () => context.push(AppRoutes.personalSubscription),
                          color: colorScheme.primary,
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
    final profileAsync = ref.watch(userProfileProvider);
    final avatarFileAsync = ref.watch(avatarFileProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
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
                        return Image.file(file, fit: BoxFit.cover, width: 72, height: 72);
                      }
                      return _ProfileAvatarPlaceholder(name: profile.name);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (final _, final _) =>
                        _ProfileAvatarPlaceholder(name: profile.name),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (final _, final _) =>
                    Icon(Icons.person, size: 36, color: colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: profileAsync.when(
              data: (final profile) {
                if (profile == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('尚未建立個人資料', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('前往編輯個人資料完成設定', style: theme.textTheme.bodyMedium),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: theme.textTheme.titleLarge),
                    if (profile.email?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.email!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '管理你的個人資料、訂閱與帳號設定',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (final _, final _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('載入個人資料失敗', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('請稍後再試', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarPlaceholder extends StatelessWidget {
  const _ProfileAvatarPlaceholder({required this.name});

  final String name;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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

class _MySectionHeader extends StatelessWidget {
  const _MySectionHeader({required this.title});

  final String title;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 0.4,
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
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
                  indent: 68,
                  endIndent: 20,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              child,
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MyActionTile extends StatelessWidget {
  const _MyActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
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
