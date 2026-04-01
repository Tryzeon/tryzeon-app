import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/usecases/get_app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_plan_model.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_capabilities_repository.dart';
import 'package:typed_result/typed_result.dart';

class SubscriptionCapabilitiesRepositoryImpl
    implements SubscriptionCapabilitiesRepository {
  SubscriptionCapabilitiesRepositoryImpl({
    required final GetAppSubscriptionEntitlement getAppSubscriptionEntitlementUseCase,
    required final SubscriptionCapabilitiesRemoteDataSource remoteDataSource,
  }) : _getAppSubscriptionEntitlementUseCase = getAppSubscriptionEntitlementUseCase,
       _remoteDataSource = remoteDataSource;

  final GetAppSubscriptionEntitlement _getAppSubscriptionEntitlementUseCase;
  final SubscriptionCapabilitiesRemoteDataSource _remoteDataSource;

  @override
  Future<Result<SubscriptionCapabilities, Failure>>
  getCurrentSubscriptionCapabilities() async {
    final entitlementResult = await _getAppSubscriptionEntitlementUseCase();
    if (entitlementResult.isFailure) {
      return Err(entitlementResult.getError()!);
    }

    final entitlement = entitlementResult.get()!;
    final capabilityPlanId = _resolveCapabilityPlanId(entitlement);

    try {
      final planInfo = await _remoteDataSource.getPlanCapabilities(capabilityPlanId);
      return Ok(_toCapabilities(entitlement, planInfo));
    } catch (e) {
      return Err(
        ServerFailure('Failed to load subscription capabilities for $capabilityPlanId'),
      );
    }
  }

  String _resolveCapabilityPlanId(final AppSubscriptionEntitlement entitlement) {
    return switch (entitlement.tier) {
      AppSubscriptionTier.max => AppConstants.entitlementMaxId,
      AppSubscriptionTier.pro => AppConstants.entitlementProId,
      AppSubscriptionTier.free => AppConstants.entitlementFreeId,
    };
  }

  SubscriptionCapabilities _toCapabilities(
    final AppSubscriptionEntitlement entitlement,
    final SubscriptionPlanModel planInfo,
  ) {
    return SubscriptionCapabilities(
      requiresWatermark: entitlement.isFree,
      hasVideoAccess: planInfo.videoLimit > 0,
      wardrobeLimit: planInfo.wardrobeLimit,
    );
  }
}
