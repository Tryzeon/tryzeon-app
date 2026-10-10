import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/presentation/widgets/app_page_header.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

class StoreAccountHeader extends StatelessWidget {
  const StoreAccountHeader({super.key});

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: '我的帳戶',
          action: IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () => context.push(AppRoutes.dashboardSettings),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _ProfileHeader(),
        ),
      ],
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  static const double _logoSize = 56;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final profileAsync = ref.watch(storeProfileProvider);
    final profile = profileAsync.value;
    final isLoading = profileAsync.isLoading && !profileAsync.hasValue;

    final String name;
    if (profile != null) {
      name = profile.name;
    } else if (profileAsync.hasError) {
      name = '載入店家資料失敗';
    } else if (isLoading) {
      name = '店家名稱載入中';
    } else {
      name = '尚未建立店家資料';
    }

    final logoUrl = profile?.logoUrl;
    final fallbackLogo = Icon(
      Icons.storefront_outlined,
      color: colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: () => context.push(AppRoutes.dashboardSettingsProfile),
      borderRadius: AppRadius.cardAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Skeletonizer(
          enabled: isLoading,
          child: Row(
            children: [
              Container(
                width: _logoSize,
                height: _logoSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.antiAlias,
                child: logoUrl == null || logoUrl.isEmpty
                    ? fallbackLogo
                    : CachedNetworkImage(
                        imageUrl: logoUrl,
                        width: _logoSize,
                        height: _logoSize,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        errorWidget: (final context, final url, final error) =>
                            fallbackLogo,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
