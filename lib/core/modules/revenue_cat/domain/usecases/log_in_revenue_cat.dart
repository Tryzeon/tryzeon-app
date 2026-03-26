import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:typed_result/typed_result.dart';

class LogInRevenueCat {
  const LogInRevenueCat(this._repository);

  final RevenueCatRepository _repository;

  Future<Result<void, Failure>> call(final String userId) => _repository.logIn(userId);
}
