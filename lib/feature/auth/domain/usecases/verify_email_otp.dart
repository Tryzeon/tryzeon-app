import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'verify_email_otp.freezed.dart';

@freezed
sealed class VerifyEmailOtpParams with _$VerifyEmailOtpParams {
  const factory VerifyEmailOtpParams({
    required final String email,
    required final String token,
    required final UserType userType,
  }) = _VerifyEmailOtpParams;
}

class VerifyEmailOtp {
  VerifyEmailOtp(this._repository);
  final AuthRepository _repository;

  Future<Result<void, Failure>> call(final VerifyEmailOtpParams params) {
    return _repository.verifyEmailOtp(
      email: params.email,
      token: params.token,
      userType: params.userType,
    );
  }
}
