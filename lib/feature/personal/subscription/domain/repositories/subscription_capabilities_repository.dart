import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class SubscriptionCapabilitiesRepository {
  Future<Result<SubscriptionCapabilities, Failure>> getCurrentSubscriptionCapabilities();
}
