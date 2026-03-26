import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/modules/revenue_cat/data/repositories/revenue_cat_repository_impl.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/usecases/get_app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/usecases/log_in_revenue_cat.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/usecases/log_out_revenue_cat.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/usecases/restore_purchases.dart';
import 'package:typed_result/typed_result.dart';

part 'revenue_cat_providers.g.dart';

// ── Repository ──────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
RevenueCatRepository revenueCatRepository(final Ref ref) {
  return RevenueCatRepositoryImpl();
}

// ── Use Case Providers ───────────────────────────────────────────────────────

@riverpod
GetAppSubscriptionEntitlement getAppSubscriptionEntitlementUseCase(final Ref ref) {
  return GetAppSubscriptionEntitlement(ref.watch(revenueCatRepositoryProvider));
}

@riverpod
LogInRevenueCat logInRevenueCatUseCase(final Ref ref) {
  return LogInRevenueCat(ref.watch(revenueCatRepositoryProvider));
}

@riverpod
LogOutRevenueCat logOutRevenueCatUseCase(final Ref ref) {
  return LogOutRevenueCat(ref.watch(revenueCatRepositoryProvider));
}

@riverpod
RestorePurchases restorePurchasesUseCase(final Ref ref) {
  return RestorePurchases(ref.watch(revenueCatRepositoryProvider));
}

@riverpod
Future<AppSubscriptionEntitlement> appSubscriptionEntitlement(final Ref ref) async {
  final useCase = ref.watch(getAppSubscriptionEntitlementUseCaseProvider);
  final result = await useCase();

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}
