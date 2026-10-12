import 'package:tryzeon/core/error/failures.dart';

class AvatarMissingFailure extends Failure {
  const AvatarMissingFailure([super.message]);

  @override
  String get defaultMessage => '請先選擇試穿模特才能開始試穿呦！';
}
