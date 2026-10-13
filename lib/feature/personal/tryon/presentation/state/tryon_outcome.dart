import 'package:tryzeon/core/error/failures.dart';
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

/// [isVideo] selects the upgrade copy.
class TryonRateLimited extends TryonOutcome {
  const TryonRateLimited(super.requestId, {required this.isVideo});

  final bool isVideo;
}

class TryonFailed extends TryonOutcome {
  const TryonFailed(super.requestId, this.failure);

  final Failure failure;
}
