import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/customer_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:typed_result/typed_result.dart';

class RestorePurchases {
  const RestorePurchases(this._repository);

  final RevenueCatRepository _repository;

  Future<Result<CustomerEntitlement, Failure>> call() => _repository.restorePurchases();
}
