import 'dart:async';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:tryzeon/core/modules/analytics/data/dtos/analytics_event_dto.dart';
import 'package:tryzeon/core/modules/analytics/data/mappers/analytics_mappr.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/services/analytics_event_queue.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class AnalyticsEventQueueImpl implements AnalyticsEventQueue {
  AnalyticsEventQueueImpl(
    this._remoteDataSource, {
    this.batchSize = 10,
    this.flushDelay = const Duration(seconds: 5),
    this.maxQueueSize = 100,
  });

  final AnalyticsRemoteDataSource _remoteDataSource;
  static const _mappr = AnalyticsMappr();

  final int batchSize;
  final Duration flushDelay;
  final int maxQueueSize;

  final List<AnalyticsEvent> _queue = [];
  Timer? _flushTimer;

  @override
  void enqueue(final AnalyticsEvent event) {
    if (_queue.length >= maxQueueSize) {
      AppLogger.warning('Analytics queue full, dropping oldest event');
      _queue.removeAt(0);
    }

    _queue.add(event);

    _flushTimer?.cancel();

    if (_queue.length >= batchSize) {
      _flush();
    } else {
      _flushTimer = Timer(flushDelay, _flush);
    }
  }

  Future<Result<void, Failure>> _flush() async {
    _flushTimer?.cancel();

    if (_queue.isEmpty) return const Ok(null);

    final eventsToUpload = List<AnalyticsEvent>.from(_queue);
    _queue.clear();

    try {
      await _remoteDataSource.uploadAnalyticsEvents(
        _mappr.convertList<AnalyticsEvent, AnalyticsEventDto>(eventsToUpload),
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload analytics events', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> forceFlush() => _flush();
}
