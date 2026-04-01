import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetAppSubscriptionEntitlement {
  const GetAppSubscriptionEntitlement(this._repository);

  final RevenueCatRepository _repository;

  Future<Result<AppSubscriptionEntitlement, Failure>> call() async {
    final result = await _repository.getAppSubscriptionEntitlement();

    if (result.isFailure) {
      return const Ok(
        AppSubscriptionEntitlement(
          tier: AppSubscriptionTier.free,
          expirationDate: null,
          productIdentifier: null,
        ),
      );
    }

    return result;
  }
}
