import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/home/presentation/widgets/store_home_header.dart';
import 'package:tryzeon/feature/store/home/presentation/widgets/store_traffic_dashboard.dart';
import 'package:tryzeon/feature/store/products/presentation/widgets/product_list_section.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

class StoreHomePage extends HookConsumerWidget {
  const StoreHomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(storeProfileProvider);
    final profile = profileAsync.maybeWhen(
      data: (final profile) => profile,
      orElse: () => null,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部標題欄
              StoreHomeHeader(profile: profile),

              // 內容區域
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([refreshAnalytics(ref), refreshProducts(ref)]);
                  },
                  color: colorScheme.primary,
                  child: const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [StoreTrafficDashboard(), ProductListSection()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              context.push('/store/products/add');
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 65,
              height: 65,
              child: Icon(Icons.add_rounded, color: colorScheme.onPrimary, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
