import 'dart:async';

import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class AnalyticsEventQueueService {
  AnalyticsEventQueueService({
    required this.uploadCallback,
    this.batchSize = 10,
    this.flushDelay = const Duration(seconds: 5),
    this.maxQueueSize = 100,
  });

  final Future<void> Function(List<AnalyticsEvent> events) uploadCallback;

  final int batchSize;
  final Duration flushDelay;
  final int maxQueueSize;

  final List<AnalyticsEvent> _queue = [];
  Timer? _flushTimer;

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

  Future<void> _flush() async {
    _flushTimer?.cancel();

    if (_queue.isEmpty) {
      return;
    }

    final eventsToUpload = List<AnalyticsEvent>.from(_queue);
    _queue.clear();

    try {
      await uploadCallback(eventsToUpload);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload analytics events', e, stackTrace);
      // Don't re-queue on failure - just drop the events
    }
  }

  Future<void> forceFlush() async {
    await _flush();
  }

  void dispose() {
    _flushTimer?.cancel();
    _queue.clear();
  }
}
