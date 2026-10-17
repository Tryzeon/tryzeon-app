import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_traffic_totals.dart';
import 'package:tryzeon/feature/store/analytics/domain/usecases/get_product_analytics_summaries.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../support/store_test_doubles.dart';

class _EmittingStoreProfile extends StoreProfileNotifier {
  @override
  Future<StoreProfile?> build() async => storeProfile();

  void emit(final StoreProfile profile) => state = AsyncData(profile);
}

class _CountingSummaries implements GetProductAnalyticsSummaries {
  var calls = 0;

  @override
  Future<Result<List<ProductAnalyticsSummary>, Failure>> call(
    final GetProductAnalyticsSummariesParams params,
  ) async {
    calls++;
    return const Ok([]);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('saving the store profile does not refetch summaries', () async {
    final summaries = _CountingSummaries();
    final container = ProviderContainer(
      overrides: [
        storeProfileProvider.overrideWith(_EmittingStoreProfile.new),
        getProductAnalyticsSummariesProvider.overrideWithValue(summaries),
      ],
    );
    addTearDown(container.dispose);
    container.listen(productAnalyticsSummariesProvider, (final _, final _) {});
    await container.read(productAnalyticsSummariesProvider.future);

    (container.read(storeProfileProvider.notifier) as _EmittingStoreProfile)
        .emit(storeProfile(name: 'renamed'));
    await container.read(productAnalyticsSummariesProvider.future);

    expect(summaries.calls, 1);
  });

  test('storeTrafficTotals aggregates the month summaries', () async {
    final container = ProviderContainer(
      overrides: [
        productAnalyticsSummariesProvider.overrideWith(
          () => FakeAnalyticsSummaries(
            (final _) async => [
              summary('a', views: 100, tryons: 10, clicks: 2),
              summary('b', views: 50, tryons: 20, clicks: 1),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final totals = await container.read(storeTrafficTotalsProvider.future);

    expect(
      totals,
      const StoreTrafficTotals(
        viewCount: 150,
        tryonCount: 30,
        purchaseClickCount: 3,
      ),
    );
  });
}
