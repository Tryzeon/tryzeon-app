import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event_type.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/track_product_purchase_click.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/track_product_view.dart';
import 'package:typed_result/typed_result.dart';

class _RecordingQueue implements AnalyticsEventQueue {
  final List<AnalyticsEvent> events = [];

  @override
  void enqueue(final AnalyticsEvent event) => events.add(event);

  @override
  Future<Result<void, Failure>> forceFlush() async => const Ok(null);
}

void main() {
  late _RecordingQueue queue;
  final product = ShopProduct(
    id: 'p1',
    storeInfo: const ShopStoreInfo(id: 's1', name: '小店', channels: {}),
    name: '碎花洋裝',
    categoryId: 'c1',
    garmentType: GarmentType.onePiece,
    price: 1280,
    imagePaths: const [],
    imageUrls: const [],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() => queue = _RecordingQueue());

  test('a view is queued against the product and its store', () {
    TrackProductView(queue)(product);

    expect(queue.events.single.productId, 'p1');
    expect(queue.events.single.storeId, 's1');
    expect(queue.events.single.eventType, AnalyticsEventType.view);
  });

  test('a purchase click is queued as its own event type', () {
    TrackProductPurchaseClick(queue)(product);

    expect(queue.events.single.eventType, AnalyticsEventType.purchaseClick);
  });
}
