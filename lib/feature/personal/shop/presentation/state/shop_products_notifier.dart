import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/list_shop_products.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'shop_products_notifier.freezed.dart';
part 'shop_products_notifier.g.dart';

@freezed
sealed class ShopProductsState with _$ShopProductsState {
  const factory ShopProductsState({
    required final List<ShopProduct> items,
    required final bool hasMore,
    @Default(false) final bool isLoadingMore,
  }) = _ShopProductsState;
}

@riverpod
class ShopProductsNotifier extends _$ShopProductsNotifier
    with PullToRefresh<ShopProductsState> {
  static const _pageSize = 20;

  @override
  Future<ShopProductsState> build(final ShopFilter filter) async {
    final result = await _fetchFirstPage(ref.watch(listShopProductsProvider));
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  Future<Result<void, Failure>> refresh() =>
      applyRefresh(() => _fetchFirstPage(ref.read(listShopProductsProvider)));

  Future<Result<ShopProductsState, Failure>> _fetchFirstPage(
    final ListShopProducts useCase,
  ) async {
    final result = await useCase(filter: filter, limit: _pageSize, offset: 0);
    return result.map(
      (final items) =>
          ShopProductsState(items: items, hasMore: items.length == _pageSize),
    );
  }

  Future<void> loadMore() async {
    final ref = this.ref; // capture THIS build's Ref to detect rebuild/dispose
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final loading = current.copyWith(isLoadingMore: true);
    state = AsyncData(loading);

    final useCase = ref.read(listShopProductsProvider);
    final result = await useCase(
      filter: filter,
      limit: _pageSize,
      offset: current.items.length,
    );

    // A refresh that landed meanwhile replaced the list this page would extend.
    if (!ref.mounted || !identical(state.value, loading)) return;

    if (result.isFailure) {
      AppLogger.warning('Failed to load more shop products', result.getError());
      state = AsyncData(current.copyWith(isLoadingMore: false));
      return;
    }

    final more = result.get()!;
    state = AsyncData(
      ShopProductsState(
        items: [...current.items, ...more],
        hasMore: more.length == _pageSize,
        isLoadingMore: false,
      ),
    );
  }
}
