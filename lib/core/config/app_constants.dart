import 'package:tryzeon/core/router/app_routes.dart';

class AppConstants {
  static const String webBaseUrl = 'https://tryzeon.com';
  static const String storeOnboardingFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLScu_hKsOTUVcuB0R3sKnRh9cAbn7zchO7W8izdgG1N9-WC9AQ/viewform';
  static const String authCallbackUrl = 'com.tryzeon.app://login-callback';
  static const String googleMapsQueryUrl =
      'https://www.google.com/maps/search/?api=1&query=';
  static const String googleServerClientId =
      '947162907000-46pmc6k02mdftuddmvpapahqt4nnnui1.apps.googleusercontent.com';
  static const String lineChannelId = '2010556446';

  static String productWebUrl(
    final String productId, {
    final String? colorId,
  }) => Uri.parse('$webBaseUrl/product/$productId')
      .replace(
        queryParameters: colorId == null
            ? null
            : {AppRoutes.queryColor: colorId},
      )
      .toString();

  static String storeWebUrl({required final String id, final String? slug}) =>
      '$webBaseUrl/store/${slug ?? id}';

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
  static const int maxProductColors = 10;
  static const int maxTryonGarments = 3;
  static const int otpResendCountdownSeconds = 60;
  static const int otpCodeLength = 6;
  static const int cacheSchemaVersion = 8;
  static const double productVisibilityThreshold = 0.5;
  static const int signedUrlTtlSeconds = 3600;

  // RevenueCat
  static const String entitlementFreeId = 'free';
  static const String entitlementProId = 'pro';
  static const String entitlementMaxId = 'max';

  // Shared Preferences Keys
  static const String keyTryonScenePrompt = 'tryon_scene_prompt';
  static const String keyTryonStylingPrompt = 'tryon_styling_prompt';
  static const String keyTryonTransitionPrompt = 'tryon_transition_prompt';
  static const String keyTryonEngine = 'tryon_engine';
  static const String keyOwnPhotoInviteDismissed = 'own_photo_invite_dismissed';
  static const String keyStoreTutorialFinishedPrefix =
      'store_tutorial_finished_';

  static const Duration staleDurationProductCategories = Duration(days: 7);
  static const Duration staleDurationUserProfile = Duration(days: 7);
  static const Duration staleDurationStoreProfile = Duration(days: 7);
  static const Duration staleDurationSubscriptionTier = Duration(days: 7);
}
