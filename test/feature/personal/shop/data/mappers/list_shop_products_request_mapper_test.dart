import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/data/mappers/list_shop_products_request_mapper.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';

void main() {
  Map<String, dynamic> params(final ShopFilter filter) =>
      toListShopProductsRequest(filter, limit: 20, offset: 40).toJson();

  test('an empty filter sends every filter as null', () {
    expect(params(const ShopFilter()), {
      'p_store_id': null,
      'p_search_query': null,
      'p_category_ids': null,
      'p_min_price': null,
      'p_max_price': null,
      'p_channels': null,
      'p_gender': null,
      'p_materials': null,
      'p_elasticities': null,
      'p_fits': null,
      'p_thicknesses': null,
      'p_styles': null,
      'p_seasons': null,
      'p_sort_column': 'created_at',
      'p_sort_ascending': false,
      'p_user_lat': null,
      'p_user_lng': null,
      'p_limit': 20,
      'p_offset': 40,
    });
  });

  test('picked filters are sent by their wire values', () {
    final json = params(
      const ShopFilter(
        storeId: 's1',
        searchQuery: '洋裝',
        categories: {'c1'},
        minPrice: 100,
        maxPrice: 900,
        gender: ProductGender.female,
        materials: {'cotton'},
        fits: {ProductFit.regular},
        styles: {ClothingStyle.korean},
        seasons: {ProductSeason.summer},
        sort: ShopSort.priceLowToHigh(),
      ),
    );

    expect(json['p_store_id'], 's1');
    expect(json['p_search_query'], '洋裝');
    expect(json['p_category_ids'], ['c1']);
    expect(json['p_min_price'], 100);
    expect(json['p_max_price'], 900);
    expect(json['p_gender'], 'female');
    expect(json['p_materials'], ['cotton']);
    expect(json['p_fits'], ['regular']);
    expect(json['p_styles'], ['korean']);
    expect(json['p_seasons'], ['summer']);
    expect(json['p_sort_column'], 'price');
    expect(json['p_sort_ascending'], true);
  });

  test('blank search and empty groups count as no filter', () {
    final json = params(
      const ShopFilter(searchQuery: '', categories: {}, styles: {}),
    );

    expect(json['p_search_query'], isNull);
    expect(json['p_category_ids'], isNull);
    expect(json['p_styles'], isNull);
  });

  test('a channel subset is sent as codes; all channels as no filter', () {
    final some = {StoreChannel.values.last};

    expect(
      params(ShopFilter(channels: some))['p_channels'],
      StoreChannel.codesFromSet(some),
    );
    expect(
      params(ShopFilter(channels: StoreChannel.values.toSet()))['p_channels'],
      isNull,
    );
  });

  test('proximity sort sends the user location', () {
    final json = params(
      const ShopFilter(
        sort: ShopSort.proximity(latitude: 25.03, longitude: 121.56),
      ),
    );

    expect(json['p_sort_column'], 'proximity');
    expect(json['p_sort_ascending'], true);
    expect(json['p_user_lat'], 25.03);
    expect(json['p_user_lng'], 121.56);
  });
}
