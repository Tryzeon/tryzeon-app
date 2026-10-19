import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';

/// Decouples the controller's logic from the UI reaction (haptics,
/// notifications, upgrade dialog) performed elsewhere. [requestId] is the id
/// of the gallery entry the run placed, or would have placed.
sealed class TryonOutcome {
  const TryonOutcome(this.requestId);

  final String requestId;
}

class TryonSucceeded extends TryonOutcome {
  TryonSucceeded(this.result) : super(result.id);

  final TryonResult result;
}

/// The user dropped the pending entry before the run settled.
class TryonCancelled extends TryonOutcome {
  const TryonCancelled(super.requestId);
}

class TryonAvatarMissing extends TryonOutcome {
  const TryonAvatarMissing(super.requestId);
}

/// [isVideo] and [quota] select the limit copy; [quota] is null when the
/// server sent no snapshot.
class TryonQuotaExceeded extends TryonOutcome {
  const TryonQuotaExceeded(
    super.requestId, {
    required this.isVideo,
    this.quota,
  });

  final bool isVideo;
  final UsageQuota? quota;
}

class TryonFailed extends TryonOutcome {
  const TryonFailed(super.requestId, this.failure);

  final Failure failure;
}
