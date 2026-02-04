class AppConstants {
  // URLs
  static const String storeOnboardingFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLScu_hKsOTUVcuB0R3sKnRh9cAbn7zchO7W8izdgG1N9-WC9AQ/viewform';
  static const String authCallbackUrl = 'io.supabase.tryzeon://login-callback';

  // Supabase Tables
  static const String tableUserProfiles = 'user_profiles';
  static const String tableStoreProfiles = 'store_profiles';
  static const String tableProducts = 'products';
  static const String tableProductVariants = 'product_variants';
  static const String tableProductCategories = 'product_categories';
  static const String tableSubscriptions = 'subscriptions';
  static const String tableWardrobeItems = 'wardrobe_items';
  static const String tableAnalyticsEvents = 'analytics_events';

  // Supabase Buckets
  static const String bucketStoreLogos = 'store-logos';
  static const String bucketProductImages = 'product-images';
  static const String bucketUserAvatars = 'user-avatars';
  static const String bucketWardrobeImages = 'wardrobe-images';

  // Supabase Functions
  static const String functionChat = 'chat';
  static const String functionTryon = 'tryon';
  static const String functionLogAnalyticsEvent = 'log_analytics_event';

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
  static const int otpResendCountdownSeconds = 60;
  static const int otpCodeLength = 6;

  // Wardrobe Limits
  static const int wardrobeLimitFree = 20;
  static const int wardrobeLimitPro = 50;
  static const int wardrobeLimitMax = 100;

  // Shared Preferences Keys
  static const String keyRecommendNearbyShops = 'recommend_nearby_shops';
}
