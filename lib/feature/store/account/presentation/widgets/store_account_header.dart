import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/actions/share_link.dart';
import 'package:tryzeon/core/presentation/widgets/app_page_header.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
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
          child: _StoreIdentityRow(),
        ),
      ],
    );
  }
}

class _StoreIdentityRow extends ConsumerWidget {
  const _StoreIdentityRow();

  static const double _logoSize = 60;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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

    final channels = profile == null
        ? ''
        : StoreChannel.listFromSet(
            profile.channels,
          ).map((final c) => c.label).join(' · ');

    final logoUrl = profile?.logoUrl;
    final fallbackLogo = Icon(
      Icons.storefront_outlined,
      color: colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Expanded(
          child: InkWell(
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
                        color: colorScheme.surfaceContainerLow,
                      ),
                      foregroundDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outline),
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
                              errorWidget:
                                  (final context, final url, final error) =>
                                      fallbackLogo,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (channels.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              channels,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (profile != null) ...[
          const SizedBox(width: AppSpacing.smMd),
          _ShareButton(
            url: AppConstants.storeWebUrl(id: profile.id, slug: profile.slug),
          ),
        ],
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.url});

  final String url;

  @override
  Widget build(final BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => shareLink(context, url),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      icon: Icon(Icons.adaptive.share, size: AppSpacing.md),
      label: const Text('分享'),
    );
  }
}
