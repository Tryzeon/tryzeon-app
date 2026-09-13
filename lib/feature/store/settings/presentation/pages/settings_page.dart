import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:tryzeon/core/presentation/widgets/app_action_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/loading_overlay.dart';
import 'package:tryzeon/core/presentation/widgets/nav_row.dart';
import 'package:tryzeon/core/presentation/widgets/section_label.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/presentation/widgets/version_info.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/common/settings/presentation/actions/account_actions.dart';
import 'package:tryzeon/feature/common/settings/providers/settings_controller.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreSettingsPage extends HookConsumerWidget {
  const StoreSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBusy = ref.watch(settingsControllerProvider).isLoading;
    final profile = ref.watch(storeProfileProvider).value;

    Future<void> openContactLink(final String url, final String label) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      if (!context.mounted) return;
      TopNotification.show(context, message: '目前無法開啟 $label 連結');
    }

    Future<void> handleContactUs() async {
      await showAppActionSheet(
        context,
        title: '聯絡我們',
        actions: [
          AppMenuAction(
            icon: SimpleIcons.line,
            title: 'LINE 官方帳號',
            onTap: () => openContactLink('https://lin.ee/rY3VZMB', 'LINE'),
          ),
          AppMenuAction(
            icon: SimpleIcons.instagram,
            title: 'Instagram',
            onTap: () =>
                openContactLink('https://www.instagram.com/tryzeon/', 'Instagram'),
          ),
        ],
      );
    }

    return LoadingOverlay(
      isLoading: isBusy,
      child: Scaffold(
        appBar: AppBar(title: const Text('設定')),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('店家'),
                NavRow(
                  icon: Icons.storefront_outlined,
                  title: '店家資料',
                  trailingValue: profile?.name,
                  isFirst: true,
                  onTap: () => context.push(AppRoutes.dashboardSettingsProfile),
                ),
                const SectionLabel('支援'),
                NavRow(
                  icon: Icons.swap_horiz_rounded,
                  title: '切換到個人帳號',
                  isFirst: true,
                  onTap: () => confirmAndSwitchTo(context, UserType.personal),
                ),
                NavRow(
                  icon: Icons.chat_bubble_outline,
                  title: '聯絡我們',
                  onTap: handleContactUs,
                ),
                SectionLabel('危險區域', color: colorScheme.error),
                NavRow(
                  icon: Icons.logout,
                  title: '登出',
                  isDestructive: true,
                  isFirst: true,
                  showChevron: false,
                  onTap: () => confirmAndSignOut(context),
                ),
                NavRow(
                  icon: Icons.delete_outline,
                  title: '刪除帳號',
                  isDestructive: true,
                  showChevron: false,
                  onTap: () => confirmAndDeleteAccount(context),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const VersionInfo(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
