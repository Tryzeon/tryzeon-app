import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/daily_usage/data/dtos/daily_usage_dto.dart';
import 'package:tryzeon/feature/common/daily_usage/data/mappers/daily_usage_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';

@AutoMappr([MapType<DailyUsageDto, DailyUsage>()])
class DailyUsageMappr extends $DailyUsageMappr {
  const DailyUsageMappr();
}
