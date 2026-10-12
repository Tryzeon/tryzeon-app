import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';

abstract final class AppRoutes {
  static const String login = '/login';

  static const String paramId = 'id';
  static const String paramStoreId = 'storeId';
  static const String paramProductId = 'productId';
  static const String queryPath = 'path';

  static const String personalRoot = '/personal';
  static const String dashboardRoot = '/dashboard';

  // Personal (tabs)
  static const String personalHome = '$personalRoot/home';
  static const String personalHomePhotoSegment = 'photo';
  static const String personalHomePhoto =
      '$personalHome/$personalHomePhotoSegment';
  static const String personalShop = '$personalRoot/shop';
  static const String personalShopProductSegment = 'product/:$paramId';
  static const String personalShopProduct =
      '$personalShop/$personalShopProductSegment';
  static const String personalShopStoreSegment = 'store/:$paramStoreId';
  static const String personalShopStore =
      '$personalShop/$personalShopStoreSegment';
  static const String personalShopProductPrefix = '$personalShop/product/';
  static const String personalShopStorePrefix = '$personalShop/store/';
  static const String personalChat = '$personalRoot/chat';
  static const String personalWardrobe = '$personalRoot/wardrobe';
  static const String personalWardrobeItemSegment = 'item/:$paramId';
  static const String personalWardrobeItem =
      '$personalWardrobe/$personalWardrobeItemSegment';
  static const String personalAccount = '$personalRoot/account';

  // Personal (full screen, outside shell)
  static const String personalOnboarding = '$personalRoot/onboarding';
  static const String personalSettings = '$personalRoot/settings';
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
  static const String personalPaywall = '$personalRoot/paywall';

  // Store owner dashboard (tabs)
  static const String dashboardProducts = '$dashboardRoot/products';
  static const String dashboardAccount = '$dashboardRoot/account';

  // Store owner dashboard (full screen, outside shell)
  static const String dashboardOnboarding = '$dashboardRoot/onboarding';
  static const String dashboardSettings = '$dashboardRoot/settings';
  static const String dashboardSettingsProfileSegment = 'profile';
  static const String dashboardSettingsProfile =
      '$dashboardSettings/$dashboardSettingsProfileSegment';
  static const String dashboardProductAdd = '$dashboardRoot/products/add';
  static const String dashboardProductDetail =
      '$dashboardRoot/products/:$paramId';

  // Deep link content routes (top-level, redirect to feature routes).
  // Singular on purpose: tryzeon.com/products is the marketing section
  // (/products/virtual-try-on), and the AASA file declares /product/* and
  // /store/*. Pluralising these would collide and break live Universal Links.
  static const String deepLinkProduct = '/product/:$paramProductId';
  static const String deepLinkStore = '/store/:$paramStoreId';

  static String homeForUserType(final UserType userType) {
    return userType == UserType.store ? dashboardAccount : personalHome;
  }

  static String personalHomePhotoPath(final String filePath) => Uri(
    path: personalHomePhoto,
    queryParameters: {queryPath: filePath},
  ).toString();

  static String personalShopProductPath(final String productId) =>
      personalShopProduct.replaceFirst(':$paramId', productId);

  static String personalShopStorePath(final String storeId) =>
      personalShopStore.replaceFirst(':$paramStoreId', storeId);

  static String personalWardrobeItemPath(final String itemId) =>
      personalWardrobeItem.replaceFirst(':$paramId', itemId);

  static String dashboardProductDetailPath(final String productId) =>
      dashboardProductDetail.replaceFirst(':$paramId', productId);
}
