import 'package:tryzeon/core/modules/revenue_cat/domain/entities/customer_entitlement.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class RevenueCatRepository {
  /// Returns the current Pro entitlement status for the logged-in user.
  Future<Result<CustomerEntitlement>> getProEntitlement();

  /// Logs in the given [userId] to RevenueCat (call after Supabase sign-in).
  Future<Result<void>> logIn(final String userId);

  /// Logs out of RevenueCat (call after Supabase sign-out / account deletion).
  Future<Result<void>> logOut();

  /// Restores previous purchases.
  Future<Result<CustomerEntitlement>> restorePurchases();
}
