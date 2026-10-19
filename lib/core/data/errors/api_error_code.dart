/// Error codes our backend shares across every endpoint
/// (supabase/functions/_shared/errors.ts). A code only one endpoint sends is a
/// constant on that endpoint's datasource instead.
abstract final class ApiErrorCode {
  static const String rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
  static const String quotaExceeded = 'QUOTA_EXCEEDED';
  static const String serviceBusy = 'SERVICE_BUSY';
  static const String validation = 'VALIDATION_ERROR';
}
