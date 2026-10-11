import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/modules/revenue_cat/data/services/subscription_entitlement_service_impl.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/services/subscription_entitlement_service.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

part 'revenue_cat_providers.g.dart';

@Riverpod(keepAlive: true)
SubscriptionEntitlementService subscriptionEntitlementService(final Ref ref) {
  return SubscriptionEntitlementServiceImpl();
}

/// Kept alive so one RevenueCat listener backs the whole app: every screen reads
/// the same entitlement and sees each change at once.
@Riverpod(keepAlive: true)
Stream<AppSubscriptionEntitlement> appSubscriptionEntitlement(final Ref ref) {
  return ref.watch(subscriptionEntitlementServiceProvider).watchEntitlement();
}

/// Keeps the RevenueCat App User ID in sync with the Supabase auth identity:
/// RevenueCat starts anonymous (configured in `main.dart`), links to the
/// Supabase UUID on sign-in, and reverts to a fresh anonymous id on sign-out.
///
/// Must be read once at the root widget: the subscription has to live for the
/// whole app lifecycle.
///
/// Only a *confirmed* link updates [syncedUserId] — recording the intent would
/// strand the customer on the anonymous id, and the free tier, for the rest of
/// the session whenever the first attempt fails.
@Riverpod(keepAlive: true)
void revenueCatIdentitySync(final Ref ref) {
  final service = ref.watch(subscriptionEntitlementServiceProvider);

  String? syncedUserId;

  Future<void> syncLogIn(final String userId) async {
    if (syncedUserId == userId) return;

    final result = await service.logIn(userId);
    if (result.isFailure) {
      AppLogger.error(
        'RevenueCat login failed; retrying on the next auth event',
        result.getError()!,
        StackTrace.current,
      );
      return;
    }
    syncedUserId = userId;
  }

  Future<void> syncLogOut() async {
    if (syncedUserId == null) return;

    final result = await service.logOut();
    if (result.isFailure) {
      AppLogger.error(
        'RevenueCat logout failed; the customer stays linked',
        result.getError()!,
        StackTrace.current,
      );
      return;
    }
    syncedUserId = null;
  }

  // Serialized so an id arriving mid-call is neither dropped nor raced against
  // the call already in flight.
  var pending = Future<void>.value();

  final userIdStream = ref.watch(authIdentityServiceProvider).watchUserId();
  final subscription = userIdStream.listen((final userId) {
    pending = pending.then(
      (final _) => userId == null ? syncLogOut() : syncLogIn(userId),
    );
  });

  ref.onDispose(subscription.cancel);
}
