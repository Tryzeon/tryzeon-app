import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import 'app_mappr.auto_mappr.dart';
import 'core/modules/analytics/data/mappers/analytics_mappr.dart';
import 'feature/common/product_categories/mappers/product_category_mappr.dart';
import 'feature/personal/data/mappers/personal_mappr.dart';

/// Root AutoMappr that includes all feature mapprs
/// Use this for DI and centralized mapping access
/// Note: StoreMappr is included via PersonalMappr (ShopProduct.sizes depends on ProductSize)
@AutoMappr([], includes: [AnalyticsMappr(), PersonalMappr(), ProductCategoryMappr()])
class AppMappr extends $AppMappr {
  const AppMappr();
}
