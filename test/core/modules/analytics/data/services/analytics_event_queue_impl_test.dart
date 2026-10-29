import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:tryzeon/core/modules/analytics/data/dtos/analytics_event_dto.dart';
import 'package:tryzeon/core/modules/analytics/data/services/analytics_event_queue_impl.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event_type.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRemote implements AnalyticsRemoteDataSource {
  _FakeRemote({this.error});

  final Object? error;
  final uploads = <List<Map<String, dynamic>>>[];

  @override
  Future<void> uploadAnalyticsEvents(
    final List<AnalyticsEventDto> events,
  ) async {
    uploads.add([for (final e in events) e.toJson()]);
    if (error case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

const _view = AnalyticsEvent(
  productId: 'p1',
  storeId: 's1',
  eventType: AnalyticsEventType.view,
);

void main() {
  test('a forced flush uploads the queued events as DTOs', () async {
    final remote = _FakeRemote();
    final queue = AnalyticsEventQueueImpl(remote)..enqueue(_view);

    final result = await queue.forceFlush();

    expect(result.isSuccess, isTrue);
    expect(remote.uploads.single.single['product_id'], 'p1');
  });

  test('a failed upload is reported and the batch is not re-queued', () async {
    final remote = _FakeRemote(error: const SocketException('offline'));
    final queue = AnalyticsEventQueueImpl(remote)..enqueue(_view);

    final result = await queue.forceFlush();
    await queue.forceFlush();

    expect(result.getError(), const NetworkFailure());
    expect(remote.uploads, hasLength(1));
  });

  test('a colour id survives the trip to the upload payload', () async {
    final remote = _FakeRemote();
    final queue = AnalyticsEventQueueImpl(remote)
      ..enqueue(
        const AnalyticsEvent(
          productId: 'p1',
          storeId: 's1',
          eventType: AnalyticsEventType.purchaseClick,
          colorId: 'c1',
        ),
      );

    await queue.forceFlush();

    expect(remote.uploads.single.single['color_id'], 'c1');
  });
}
