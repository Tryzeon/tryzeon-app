/// Error codes our backend shares across every endpoint (supabase/functions/_shared/errors.ts).
abstract final class ApiErrorCode {
  static const String rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
  static const String serviceBusy = 'SERVICE_BUSY';
  static const String noAvatar = 'NO_AVATAR';
  static const String aiGenerationFailed = 'AI_GENERATION_FAILED';
  static const String validation = 'VALIDATION_ERROR';
}
