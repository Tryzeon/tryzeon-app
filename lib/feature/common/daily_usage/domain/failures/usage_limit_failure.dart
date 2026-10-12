import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';

/// A [RateLimitFailure] our backend raised for a spent daily quota, carrying the
/// usage snapshot it sent so the usage cache can sync without a refetch.
class UsageLimitFailure extends RateLimitFailure {
  const UsageLimitFailure({this.usage, final String? message}) : super(message);

  final DailyUsage? usage;

  @override
  List<Object?> get props => [message, usage];
}
