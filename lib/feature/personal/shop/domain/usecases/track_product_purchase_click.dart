import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event_type.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:typed_result/typed_result.dart';

class TrackProductPurchaseClick {
  TrackProductPurchaseClick(this._analyticsQueue);
  final AnalyticsEventQueue _analyticsQueue;

  Result<void, Failure> call(final ShopProduct product) {
    _analyticsQueue.enqueue(
      AnalyticsEvent(
        productId: product.id,
        storeId: product.storeInfo.id,
        eventType: AnalyticsEventType.purchaseClick,
      ),
    );
    return const Ok(null);
  }
}
