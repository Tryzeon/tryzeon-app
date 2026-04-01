import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_capabilities_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetSubscriptionCapabilities {
  GetSubscriptionCapabilities(this._repository);

  final SubscriptionCapabilitiesRepository _repository;

  Future<Result<SubscriptionCapabilities, Failure>> call() async {
    final result = await _repository.getCurrentSubscriptionCapabilities();

    if (result.isFailure) {
      AppLogger.error(
        'Failed to fetch subscription capabilities, using defaults',
        result.getError()!,
        StackTrace.current,
      );

      return const Ok(
        SubscriptionCapabilities(
          requiresWatermark: true,
          hasVideoAccess: false,
          wardrobeLimit: AppConstants.defaultWardrobeLimit,
        ),
      );
    }

    return result;
  }
}
