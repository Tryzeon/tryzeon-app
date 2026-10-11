import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:typed_result/typed_result.dart';

abstract class AnalyticsEventQueue {
  void enqueue(final AnalyticsEvent event);

  /// Uploads whatever is queued now. A failed upload drops the batch (it is
  /// not re-queued) and is reported as an [Err].
  Future<Result<void, Failure>> forceFlush();
}
