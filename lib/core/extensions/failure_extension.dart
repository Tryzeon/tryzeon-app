import 'package:flutter/widgets.dart';
import '../error/failures.dart';

extension FailureMessage on Failure {
  String displayMessage(final BuildContext context) {
    return switch (this) {
      NetworkFailure(message: final msg?) => msg,
      NetworkFailure() => '無網路連線，請檢查您的網路設定',

      ServerFailure(message: final msg?) => msg,
      ServerFailure() => '伺服器發生錯誤，請稍後再試',

      AuthFailure(message: final msg?) => msg,
      AuthFailure() => '偵測到登入狀態異常，請重新登入',

      ValidationFailure(message: final msg?) => msg,
      ValidationFailure() => '驗證失敗，請檢查您的方案是否已達上限',

      UnknownFailure(message: final msg?) => msg,
      UnknownFailure() => '發生未知錯誤，請稍後再試',
    };
  }
}
