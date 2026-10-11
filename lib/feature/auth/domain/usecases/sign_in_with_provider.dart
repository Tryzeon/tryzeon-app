import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/entities/login_provider.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'sign_in_with_provider.freezed.dart';

@freezed
sealed class SignInWithProviderParams with _$SignInWithProviderParams {
  const factory SignInWithProviderParams({
    required final LoginProvider provider,
    required final UserType userType,
  }) = _SignInWithProviderParams;
}

class SignInWithProvider {
  SignInWithProvider(this._repository);
  final AuthRepository _repository;

  Future<Result<void, Failure>> call(final SignInWithProviderParams params) {
    return _repository.signInWithProvider(
      provider: params.provider,
      userType: params.userType,
    );
  }
}
