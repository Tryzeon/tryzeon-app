import 'package:equatable/equatable.dart';

/// Open rather than sealed so a feature can declare a failure only it raises
/// (e.g. `WardrobeFullFailure`) without core knowing about it.
abstract class Failure extends Equatable {
  const Failure([this.message]);
  final String? message;

  String get defaultMessage;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);

  @override
  String get defaultMessage => '無網路連線，請檢查您的網路設定';
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);

  @override
  String get defaultMessage => '伺服器發生錯誤，請稍後再試';
}

class AuthFailure extends Failure {
  const AuthFailure([super.message]);

  @override
  String get defaultMessage => '登入狀態異常，請稍後再試';
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);

  @override
  String get defaultMessage => '發生未知錯誤，請稍後再試';
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);

  @override
  String get defaultMessage => '驗證失敗，請檢查您的輸入';
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message]);

  @override
  String get defaultMessage => '使用次數已達上限，請升級您的方案';
}

class ServiceBusyFailure extends Failure {
  const ServiceBusyFailure([super.message]);

  @override
  String get defaultMessage => '目前使用人數較多，請稍後再試一次';
}

class UserCanceledFailure extends Failure {
  const UserCanceledFailure([super.message]);

  @override
  String get defaultMessage => '';
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);

  @override
  String get defaultMessage => '找不到資源，可能已被移除或失效';
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message]);

  @override
  String get defaultMessage => '處理時間過長而中斷，請重新嘗試；生成期間請讓 App 保持在前景';
}
