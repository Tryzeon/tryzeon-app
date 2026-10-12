import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/store/account/presentation/state/top_tried_on_products.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

part 'store_account_providers.g.dart';

@riverpod
Future<List<RankedProduct>> topTriedOnProducts(final Ref ref) async {
  final productsFuture = ref.watch(productsProvider.future);
  final summariesFuture = ref.watch(productAnalyticsSummariesProvider.future);
  return rankTopTriedOnProducts(await productsFuture, await summariesFuture);
}
