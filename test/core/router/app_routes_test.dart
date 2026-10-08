import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/router/app_routes.dart';

void main() {
  test('nested routes compose from their parent and segment', () {
    expect(AppRoutes.personalHomePhoto, '/personal/home/photo');
    expect(AppRoutes.personalShopProduct, '/personal/shop/product/:id');
    expect(AppRoutes.personalShopStore, '/personal/shop/store/:storeId');
    expect(AppRoutes.personalWardrobeItem, '/personal/wardrobe/item/:id');
    expect(AppRoutes.personalSettingsProfile, '/personal/settings/profile');
    expect(
      AppRoutes.personalSettingsBodyMeasurements,
      '/personal/settings/body-measurements',
    );
    expect(
      AppRoutes.personalSettingsStyle,
      '/personal/settings/style-preferences',
    );
    expect(AppRoutes.personalSubscription, '/personal/settings/subscription');
    expect(AppRoutes.dashboardSettingsProfile, '/dashboard/settings/profile');
  });

  test('path builders fill the route parameter', () {
    expect(
      AppRoutes.personalShopProductPath('p1'),
      '/personal/shop/product/p1',
    );
    expect(AppRoutes.personalShopStorePath('s1'), '/personal/shop/store/s1');
    expect(
      AppRoutes.personalWardrobeItemPath('w1'),
      '/personal/wardrobe/item/w1',
    );
    expect(
      AppRoutes.dashboardProductDetailPath('p1'),
      '/dashboard/products/p1',
    );
  });
}
