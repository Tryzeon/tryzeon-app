import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';

abstract final class AppRoutes {
  static const String login = '/login';

  // Personal (tabs)
  static const String personalHome = '/personal/home';
  static const String personalHomePhotoSegment = 'photo';
  static const String personalHomePhoto =
      '$personalHome/$personalHomePhotoSegment';
  static const String personalShop = '/personal/shop';
  static const String personalShopProductSegment = 'product/:id';
  static const String personalShopProduct =
      '$personalShop/$personalShopProductSegment';
  static const String personalShopStoreSegment = 'store/:storeId';
  static const String personalShopStore =
      '$personalShop/$personalShopStoreSegment';
  static const String personalChat = '/personal/chat';
  static const String personalWardrobe = '/personal/wardrobe';
  static const String personalWardrobeItemSegment = 'item/:id';
  static const String personalWardrobeItem =
      '$personalWardrobe/$personalWardrobeItemSegment';
  static const String personalAccount = '/personal/account';

  // Personal (full screen, outside shell)
  static const String personalOnboarding = '/personal/onboarding';
  static const String personalSettings = '/personal/settings';
  static const String personalSettingsProfileSegment = 'profile';
  static const String personalSettingsProfile =
      '$personalSettings/$personalSettingsProfileSegment';
  static const String personalSettingsBodyMeasurementsSegment =
      'body-measurements';
  static const String personalSettingsBodyMeasurements =
      '$personalSettings/$personalSettingsBodyMeasurementsSegment';
  static const String personalSettingsStyleSegment = 'style-preferences';
  static const String personalSettingsStyle =
      '$personalSettings/$personalSettingsStyleSegment';
  static const String personalSubscriptionSegment = 'subscription';
  static const String personalSubscription =
      '$personalSettings/$personalSubscriptionSegment';
  static const String personalPaywall = '/personal/paywall';

  // Store owner dashboard (tabs)
  static const String dashboardProducts = '/dashboard/products';
  static const String dashboardAccount = '/dashboard/account';

  // Store owner dashboard (full screen, outside shell)
  static const String dashboardOnboarding = '/dashboard/onboarding';
  static const String dashboardSettings = '/dashboard/settings';
  static const String dashboardSettingsProfileSegment = 'profile';
  static const String dashboardSettingsProfile =
      '$dashboardSettings/$dashboardSettingsProfileSegment';
  static const String dashboardProductAdd = '/dashboard/products/add';
  static const String dashboardProductDetail = '/dashboard/products/:id';

  // Deep link content routes (top-level, redirect to feature routes).
  // Singular on purpose: tryzeon.com/products is the marketing section
  // (/products/virtual-try-on), and the AASA file declares /product/* and
  // /store/*. Pluralising these would collide and break live Universal Links.
  static const String deepLinkProduct = '/product/:productId';
  static const String deepLinkStore = '/store/:storeId';

  static String homeForUserType(final UserType userType) {
    return userType == UserType.store ? dashboardAccount : personalHome;
  }

  static String personalHomePhotoPath(final String filePath) => Uri(
    path: personalHomePhoto,
    queryParameters: {'path': filePath},
  ).toString();

  static String personalShopProductPath(final String productId) =>
      personalShopProduct.replaceFirst(':id', productId);

  static String personalShopStorePath(final String storeId) =>
      personalShopStore.replaceFirst(':storeId', storeId);

  static String personalWardrobeItemPath(final String itemId) =>
      personalWardrobeItem.replaceFirst(':id', itemId);

  static String dashboardProductDetailPath(final String productId) =>
      dashboardProductDetail.replaceFirst(':id', productId);
}
