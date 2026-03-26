import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/customer_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:typed_result/typed_result.dart';

class RevenueCatRepositoryImpl implements RevenueCatRepository {
  @override
  Future<Result<CustomerEntitlement, Failure>> getProEntitlement() async {
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
  Future<Result<CustomerEntitlement, Failure>> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return Ok(_mapToEntitlement(customerInfo));
    } catch (e) {
      return Err(UnknownFailure(e.toString()));
    }
  }

  CustomerEntitlement _mapToEntitlement(final CustomerInfo customerInfo) {
    final proEntitlement =
        customerInfo.entitlements.active[AppConstants.entitlementProId];
    return CustomerEntitlement(
      isProActive: proEntitlement != null,
      expirationDate: proEntitlement?.expirationDate,
      productIdentifier: proEntitlement?.productIdentifier,
    );
  }
}
