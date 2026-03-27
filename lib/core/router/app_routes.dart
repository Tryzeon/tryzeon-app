abstract final class AppRoutes {
  // Auth
  static const String login = '/auth/login';
  static const String personalLogin = '/auth/login/personal';
  static const String storeLogin = '/auth/login/store';
  static const String emailLogin = '/auth/login/email';
  static const String authCallback = '/auth/callback';

  // Personal (tabs)
  static const String personalHome = '/personal/home';
  static const String personalShop = '/personal/shop';
  static const String personalShopProduct = '/personal/shop/product/:id';
  static const String personalShopStore = '/personal/shop/store/:storeId';
  static const String personalChat = '/personal/chat';
  static const String personalWardrobe = '/personal/wardrobe';
  static const String personalMy = '/personal/my';

  // Personal (full screen, outside shell)
  static const String personalOnboarding = '/personal/onboarding';
  static const String personalSettings = '/personal/settings';
  static const String personalSettingsProfile = '/personal/settings/profile';
  static const String personalSettingsPreferences = '/personal/settings/preferences';
  static const String personalSubscription = '/personal/subscription';

  // Store (tabs)
  static const String storeHome = '/store/home';

  // Store (full screen, outside shell)
  static const String storeOnboarding = '/store/onboarding';
  static const String storeSettings = '/store/settings';
  static const String storeSettingsProfile = '/store/settings/profile';
  static const String storeProductAdd = '/store/products/add';
  static const String storeProductDetail = '/store/products/:id';

  // Deep link content routes (top-level, redirect to feature routes)
  static const String deepLinkProduct = '/product/:productId';
  static const String deepLinkStore = '/store/:storeId';
}
