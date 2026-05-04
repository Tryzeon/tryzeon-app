class AppConstants {
  // URLs
  static const String webBaseUrl = 'https://tryzeon.com';
  static const String storeOnboardingFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLScu_hKsOTUVcuB0R3sKnRh9cAbn7zchO7W8izdgG1N9-WC9AQ/viewform';
  static const String authCallbackUrl = 'com.tryzeon.app://login-callback';
  static const String googleMapsQueryUrl =
      'https://www.google.com/maps/search/?api=1&query=';

  // Supabase Tables
  static const String tableUserProfiles = 'user_profiles';
  static const String tableStoreProfiles = 'store_profiles';
  static const String tableProducts = 'products';
  static const String tableProductVariants = 'product_variants';
  static const String tableProductCategories = 'product_categories';
  static const String tableSubscriptionPlans = 'subscription_plans';
  static const String tableWardrobeItems = 'wardrobe_items';
  static const String tableAnalyticsEvents = 'analytics_events';
  static const String tableAnalyticsProductMonthlySummary =
      'analytics_product_monthly_summary';

  // Supabase Buckets
  static const String bucketStoreLogos = 'store-logos';
  static const String bucketProductImages = 'product-images';
  static const String bucketUserAvatars = 'user-avatars';
  static const String bucketWardrobeImages = 'wardrobe-images';
  static const String bucketProductCategoryImages = 'product-categories-images';

  // Supabase Functions
  static const String functionChat = 'chat';
  static const String functionTryon = 'tryon';
  static const String functionDeleteAccount = 'delete-account';
  static const String functionLogAnalyticsEvents = 'log_analytics_events';

  // Assets
  static const String defaultProfileImage = 'assets/images/profile/default.png';
  static const String tryOnSkeleton = 'assets/images/tryon/skeleton.svg';

  // Timeouts & Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration errorToastDuration = Duration(seconds: 10);

  // Logic
  static const int maxProductImages = 3;
  static const int otpResendCountdownSeconds = 60;
  static const int otpCodeLength = 6;
  static const double productVisibilityThreshold = 0.5;

  // RevenueCat
  static const String entitlementFreeId = 'free';
  static const String entitlementProId = 'pro';
  static const String entitlementMaxId = 'max';

  // TryOn Params
  static const String paramMode = 'mode';
  static const String modeImage = 'image';
  static const String modeVideo = 'video';
  static const String paramScenePrompt = 'scenePrompt';
  static const String paramTransitionPrompt = 'transitionPrompt';

  // Shared Preferences Keys
  static const String keyRecommendNearbyShops = 'recommend_nearby_shops';
  static const String keyVideoScenePrompt = 'video_scene_prompt';
  static const String keyVideoTransitionPrompt = 'video_transition_prompt';

  // Stale Durations
  static const Duration staleDurationProductCategories = Duration(days: 7);
  static const Duration staleDurationUserProfile = Duration(days: 7);
  static const Duration staleDurationStoreProfile = Duration(days: 7);
  static const Duration staleDurationSubscriptionPlan = Duration(days: 7);
  static const Duration staleDurationShopProduct = Duration(hours: 1);
}
