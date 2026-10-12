import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/daily_usage/data/dtos/daily_usage_dto.dart';

class DailyUsageRemoteDataSource {
  DailyUsageRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;
  static const _userDailyUsageTable = 'user_daily_usage';

  /// Returns an empty model when authenticated but no row exists yet today.
  Future<DailyUsageDto> getTodayUsage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final response = await _supabase
        .from(_userDailyUsageTable)
        .select('user_id, usage_date, tryon_count, chat_count, video_count')
        .eq('user_id', user.id)
        .eq('usage_date', today)
        .maybeSingle();
    if (response == null) {
      return DailyUsageDto.empty(
        userId: user.id,
        usageDate: DateTime.parse(today),
      );
    }
    return DailyUsageDto.fromJson(response);
  }
}
