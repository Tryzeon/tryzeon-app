import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/refresh_feedback_extension.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/account/presentation/widgets/store_account_header.dart';
import 'package:tryzeon/feature/store/account/presentation/widgets/store_performance_section.dart';
import 'package:tryzeon/feature/store/account/presentation/widgets/top_products_ranking.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/store_add_product_fab.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

class StoreAccountPage extends HookConsumerWidget {
  const StoreAccountPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => [
            ref.read(storeProfileProvider.notifier).refresh(),
            ref.read(productAnalyticsSummariesProvider.notifier).refresh(),
            ref.read(productsProvider.notifier).refresh(),
          ].showFirstFailure(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              const StoreAccountHeader(),
              const SizedBox(height: AppSpacing.lg),
              const StorePerformanceSection(),
              const SizedBox(height: AppSpacing.xl),
              const TopProductsRanking(),
              SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom +
                    AppSpacing.bottomNavBarOverlap +
                    AppSpacing.md,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const StoreAddProductFab(),
    );
  }
}
