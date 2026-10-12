import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/account/presentation/pages/store_account_page.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

import '../../../../../support/store_test_doubles.dart';

void main() {
  testWidgets('pull-to-refresh reloads profile, analytics and products', (
    final tester,
  ) async {
    final profile = FakeStoreProfile(() async => null);
    final products = FakeProducts();
    final analytics = FakeAnalyticsSummaries();

    await tester.pumpWidget(
      ProviderScope(
        retry: (final _, final _) => null,
        overrides: [
          storeProfileProvider.overrideWith(() => profile),
          productsProvider.overrideWith(() => products),
          productAnalyticsSummariesProvider.overrideWith(() => analytics),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StoreAccountPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await pullToRefresh(tester, find.byType(ListView));

    expect(profile.refreshCount, 1);
    expect(analytics.refreshCount, 1);
    expect(products.refreshCount, 1);
  });
}
