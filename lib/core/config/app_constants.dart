class AppConstants {
  static const String webBaseUrl = 'https://tryzeon.com';
  static const String storeOnboardingFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLScu_hKsOTUVcuB0R3sKnRh9cAbn7zchO7W8izdgG1N9-WC9AQ/viewform';
  static const String authCallbackUrl = 'com.tryzeon.app://login-callback';
  static const String googleMapsQueryUrl =
      'https://www.google.com/maps/search/?api=1&query=';
  static const String googleServerClientId =
      '924030382971-ppc2nttqs2dn977e4b6j79i83g03bk11.apps.googleusercontent.com';
  static const String lineChannelId = '2010556446';

  static String productWebUrl(final String productId) =>
      '$webBaseUrl/product/$productId';

  static const String tableUserProfiles = 'user_profiles';
  static const String tableStoreProfiles = 'store_profiles';
  static const String tableProducts = 'products';
  static const String tableProductSizes = 'product_sizes';
  static const String tableProductCategories = 'product_categories';
  static const String tableSubscriptionTiers = 'subscription_tiers';
  static const String tableWardrobeItems = 'wardrobe_items';
  static const String tableAnalyticsProductMonthlySummary =
      'analytics_product_monthly_summary';
  static const String tableUserDailyUsage = 'user_daily_usage';
  static const String tableContentReports = 'content_reports';
  static const String tableTryonRatings = 'tryon_ratings';

  static const String bucketUserAvatars = 'user-avatars';
  static const String bucketWardrobeImages = 'wardrobe-images';

  static const String rpcLogAnalyticsEvents = 'log_analytics_events';
  static const String rpcListShopProducts = 'list_shop_products';

  static const String functionChat = 'chat';
  static const String functionTryon = 'tryon';
  static const String functionDeleteAccount = 'delete-account';
  static const String functionAnalyzeWardrobeImage = 'analyze-wardrobe-image';
  static const String functionAnalyzeProductImage = 'analyze-product-image';
  static const String functionParseSizeVoice = 'parse-size-voice';
  static const String functionStoreImages = 'store-images';
  static const String functionStoreImagesPresignLogo =
      '$functionStoreImages/presign-logo';
  static const String functionStoreImagesPresignProducts =
      '$functionStoreImages/presign-products';
  static const String functionStoreImagesDelete = '$functionStoreImages/delete';
  static const String functionLineAuth = 'line-auth';

  // Edge Function Error Codes (supabase/functions/_shared/errors.ts)
  static const String functionErrorRateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
  static const String functionErrorServiceBusy = 'SERVICE_BUSY';
  static const String functionErrorNoAvatar = 'NO_AVATAR';
  static const String functionErrorAiGenerationFailed = 'AI_GENERATION_FAILED';
  static const String functionErrorValidation = 'VALIDATION_ERROR';

  static const String presetAvatarFemale =
      'assets/images/tryon/preset_model_female.jpg';
  static const String presetAvatarMale =
      'assets/images/tryon/preset_model_male.jpg';
  static const List<String> tryonLoadingAnimations = [
    'assets/videos/tryon-loading-animation-1.mp4',
    'assets/videos/tryon-loading-animation-2.mp4',
    'assets/videos/tryon-loading-animation-3.mp4',
    'assets/videos/tryon-loading-animation-4.mp4',
    'assets/videos/tryon-loading-animation-5.mp4',
  ];
  static const String logoMark = 'assets/images/logo/tryzeon_logomark.png';

  static const ({int x, int y}) avatarAspectRatio = (x: 9, y: 16);
  static const int maxProductImages = 3;
  static const int maxTryonGarments = 3;
  static const int otpResendCountdownSeconds = 60;
  static const int otpCodeLength = 6;
  static const int cacheSchemaVersion = 5;
  static const double productVisibilityThreshold = 0.5;
  static const int signedUrlTtlSeconds = 3600;

  // RevenueCat
  static const String entitlementFreeId = 'free';
  static const String entitlementProId = 'pro';
  static const String entitlementMaxId = 'max';

  // Tryon Params
  static const String paramMode = 'mode';
  static const String paramGenerationId = 'generationId';
  static const String paramScenePrompt = 'scenePrompt';
  static const String paramStylingPrompt = 'stylingPrompt';
  static const String paramTransitionPrompt = 'transitionPrompt';
  static const String paramBaseImage = 'baseImage';
  static const String paramGarmentImages = 'images';
  static const String paramProductId = 'productId';
  static const String paramSizeId = 'sizeId';
  static const String paramWardrobeItemId = 'wardrobeItemId';
  static const String paramEngine = 'engine';

  // Shared Preferences Keys
  static const String keyTryonScenePrompt = 'tryon_scene_prompt';
  static const String keyTryonStylingPrompt = 'tryon_styling_prompt';
  static const String keyTryonTransitionPrompt = 'tryon_transition_prompt';
  static const String keyTryonEngine = 'tryon_engine';

  static const Duration staleDurationProductCategories = Duration(days: 7);
  static const Duration staleDurationUserProfile = Duration(days: 7);
  static const Duration staleDurationStoreProfile = Duration(days: 7);
  static const Duration staleDurationSubscriptionTier = Duration(days: 7);
}
