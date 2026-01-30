import 'package:flutter/widgets.dart';
import '../error/failures.dart';

extension FailureMessage on Failure {
  String message(final BuildContext context) {
    // final l10n = context.l10n;
    return switch (this) {
      DatabaseFailure _ => '資料庫發生錯誤，請稍後再試',
      CacheFailure _ => '快取資料讀取失敗',
      NetworkFailure _ => '無網路連線，請檢查您的網路設定',
      ServerFailure _ => '伺服器發生錯誤，請稍後再試',
      AuthFailure _ => '偵測到登入狀態異常，請重新登入',
      ValidationFailure _ => '資料驗證失敗，請檢查輸入內容',
      UnknownFailure(debugMessage: final msg) => msg ?? '發生未知錯誤，請稍後再試',
    };
  }
}
