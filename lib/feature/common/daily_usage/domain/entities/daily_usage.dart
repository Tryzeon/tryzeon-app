import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_usage.freezed.dart';

@freezed
sealed class DailyUsage with _$DailyUsage {
  const factory DailyUsage({
    required final String userId,
    required final DateTime usageDate,
    required final int tryonCount,
    required final int chatCount,
    required final int videoCount,
  }) = _DailyUsage;
}
