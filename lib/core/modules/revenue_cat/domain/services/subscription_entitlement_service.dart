import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class SubscriptionEntitlementService {
  /// A one-shot read is deliberately not offered: the customer identity is
  /// established asynchronously after startup, so a snapshot taken before that
  /// lands would report the anonymous customer's free tier and stay wrong for
  /// the rest of the session.
  ///
  /// Errors are delivered as [Failure]s on the stream, never folded into the
  /// free tier: a paid customer must not be told they are on free because the
  /// store happened to be unreachable. Callers decide how to degrade.
  Stream<AppSubscriptionEntitlement> watchEntitlement();

  Future<Result<void, Failure>> logIn(final String userId);

  Future<Result<void, Failure>> logOut();
}
