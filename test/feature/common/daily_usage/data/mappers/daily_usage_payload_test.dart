import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/daily_usage/data/mappers/daily_usage_payload.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';

void main() {
  test('decodes the usage snapshot inlined by the edge functions', () {
    expect(
      parseDailyUsagePayload({
        'user_id': 'u1',
        'usage_date': '2026-10-11',
        'tryon_count': 3,
        'chat_count': 5,
        'video_count': 1,
      }),
      DailyUsage(
        userId: 'u1',
        usageDate: DateTime(2026, 10, 11),
        tryonCount: 3,
        chatCount: 5,
        videoCount: 1,
      ),
    );
  });
}
