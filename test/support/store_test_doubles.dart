import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/analytics_month.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

Product product(
  final String name, {
  final ProductStatus status = ProductStatus.active,
}) {
  final now = DateTime(2026, 10, 11);
  return Product(
    id: name,
    storeId: 's1',
    name: name,
    categoryId: 'c1',
    garmentType: GarmentType.top,
    price: 100,
    colors: const [],
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

ProductAnalyticsSummary summary(
  final String id, {
  final int views = 0,
  final int tryons = 0,
  final int clicks = 0,
}) => ProductAnalyticsSummary(
  productId: id,
  viewCount: views,
  tryonCount: tryons,
  purchaseClickCount: clicks,
);

StoreProfile storeProfile({
  final String name = 'Mia Select 選物',
  final Set<StoreChannel> channels = StoreChannel.all,
  final DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime(2026, 10, 11);
  return StoreProfile(
    id: 's1',
    ownerId: 'u1',
    name: name,
    createdAt: created,
    updatedAt: created,
    channels: channels,
  );
}

Future<T> _none<T>() async => throw UnimplementedError();

class FakeStoreProfile extends StoreProfileNotifier {
  FakeStoreProfile([this._load = _none]);
  final Future<StoreProfile?> Function() _load;
  int refreshCount = 0;

  @override
  Future<StoreProfile?> build() => _load();

  @override
  Future<Result<void, Failure>> refresh() async {
    refreshCount++;
    return const Ok(null);
  }
}

class FakeProducts extends ProductsNotifier {
  FakeProducts([this._products = const []]);
  final List<Product> _products;
  int refreshCount = 0;

  @override
  Future<List<Product>> build() async => _products;

  @override
  Future<Result<void, Failure>> refresh() async {
    refreshCount++;
    return const Ok(null);
  }
}

Future<List<ProductAnalyticsSummary>> _noSummaries(
  final AnalyticsMonth month,
) async => const [];

class FakeAnalyticsSummaries extends ProductAnalyticsSummariesNotifier {
  FakeAnalyticsSummaries([this._load = _noSummaries]);
  final Future<List<ProductAnalyticsSummary>> Function(AnalyticsMonth month)
  _load;
  int refreshCount = 0;

  @override
  Future<List<ProductAnalyticsSummary>> build() =>
      _load(ref.watch(storeAnalyticsFilterProvider));

  @override
  Future<Result<void, Failure>> refresh() async {
    refreshCount++;
    return const Ok(null);
  }
}

AnalyticsMonth get currentMonth {
  final now = DateTime.now();
  return (year: now.year, month: now.month);
}

AnalyticsMonth get previousMonth {
  final now = DateTime.now();
  final previous = DateTime(now.year, now.month - 1);
  return (year: previous.year, month: previous.month);
}

void showPreviousMonth(final ProviderContainer container) {
  container.read(storeAnalyticsFilterProvider.notifier).filter = previousMonth;
}

void useNarrowScreen(final WidgetTester tester) {
  tester.view.physicalSize = const Size(320 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> pullToRefresh(
  final WidgetTester tester,
  final Finder scrollable,
) async {
  await tester.fling(scrollable, const Offset(0, 300), 1000);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}
