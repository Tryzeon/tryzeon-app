import 'package:tryzeon/core/error/failures.dart';

class WardrobeFullFailure extends Failure {
  const WardrobeFullFailure([super.message]);

  @override
  String get defaultMessage => '衣櫃已達上限';
}
