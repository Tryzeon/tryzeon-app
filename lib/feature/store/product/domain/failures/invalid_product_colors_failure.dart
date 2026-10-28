import 'package:tryzeon/core/error/failures.dart';

class InvalidProductColorsFailure extends Failure {
  const InvalidProductColorsFailure([super.message]);

  @override
  String get defaultMessage => '顏色設定不完整，請確認每個顏色都有照片，多色時名稱不可重複';
}
