import 'package:tryzeon/core/error/failures.dart';

class ColorUnavailableFailure extends Failure {
  const ColorUnavailableFailure([super.message]);

  @override
  String get defaultMessage => '店家已移除這個顏色，請重新選擇。';
}
