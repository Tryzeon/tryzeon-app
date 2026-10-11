import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/daily_usage.dart';
import '../dtos/daily_usage_dto.dart';
import 'daily_usage_mappr.auto_mappr.dart';

@AutoMappr([MapType<DailyUsageDto, DailyUsage>()])
class DailyUsageMappr extends $DailyUsageMappr {
  const DailyUsageMappr();
}
