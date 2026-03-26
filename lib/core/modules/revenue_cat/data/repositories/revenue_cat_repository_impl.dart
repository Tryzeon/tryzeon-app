import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:typed_result/typed_result.dart';

class RevenueCatRepositoryImpl implements RevenueCatRepository {
  @override
  Future<Result<AppSubscriptionEntitlement, Failure>>
  getAppSubscriptionEntitlement() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return Ok(_mapToEntitlement(customerInfo));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> logIn(final String userId) async {
    try {
      await Purchases.logIn(userId);
      return const Ok(null);
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> logOut() async {
    try {
      await Purchases.logOut();
      return const Ok(null);
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AppSubscriptionEntitlement, Failure>> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return Ok(_mapToEntitlement(customerInfo));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  AppSubscriptionEntitlement _mapToEntitlement(final CustomerInfo customerInfo) {
    final activeEntitlements = customerInfo.entitlements.active;
    final isProActive = activeEntitlements.containsKey(AppConstants.entitlementProId);
    final isMaxActive = activeEntitlements.containsKey(AppConstants.entitlementMaxId);
    final proEntitlement = activeEntitlements[AppConstants.entitlementProId];
    final maxEntitlement = activeEntitlements[AppConstants.entitlementMaxId];
    final primaryEntitlement = maxEntitlement ?? proEntitlement;

    return AppSubscriptionEntitlement(
      isProActive: isProActive,
      isMaxActive: isMaxActive,
      expirationDate: primaryEntitlement?.expirationDate,
      productIdentifier: primaryEntitlement?.productIdentifier,
    );
  }
}
