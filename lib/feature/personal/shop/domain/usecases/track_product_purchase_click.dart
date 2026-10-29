import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event_type.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:typed_result/typed_result.dart';

part 'track_product_purchase_click.freezed.dart';

@freezed
sealed class TrackProductPurchaseClickParams
    with _$TrackProductPurchaseClickParams {
  const factory TrackProductPurchaseClickParams({
    required final ShopProduct product,
    required final ProductColor? color,
  }) = _TrackProductPurchaseClickParams;
}

class TrackProductPurchaseClick {
  TrackProductPurchaseClick(this._analyticsQueue);
  final AnalyticsEventQueue _analyticsQueue;

  Result<void, Failure> call(final TrackProductPurchaseClickParams params) {
    _analyticsQueue.enqueue(
      AnalyticsEvent(
        productId: params.product.id,
        storeId: params.product.storeInfo.id,
        eventType: AnalyticsEventType.purchaseClick,
        colorId: params.color?.id,
      ),
    );
    return const Ok(null);
  }
}
