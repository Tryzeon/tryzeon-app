import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/utils/crypto_utils.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  Future<void> signInWithOAuthProvider(final OAuthProvider provider) async {
    final success = await _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: AppConstants.authCallbackUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!success) {
      throw const ServerException();
    }

    // Wait for auth state change
    final user = await _supabase.auth.onAuthStateChange
        .firstWhere((final state) => state.event == AuthChangeEvent.signedIn)
        .then((final state) => state.session?.user);

    if (user == null) {
      throw const UnauthenticatedException();
    }
  }

  Future<void> signInWithAppleNative() async {
    final rawNonce = CryptoUtils.generateNonce();
    final hashedNonce = CryptoUtils.sha256Hash(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const UnauthenticatedException();
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<void> sendEmailOTP(final String email) async {
    await _supabase.auth.signInWithOtp(email: email);
  }

  Future<void> verifyEmailOTP({
    required final String email,
    required final String token,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );

    if (response.session == null) {
      throw const UnauthenticatedException();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentSession?.user;
  }

  Future<void> deleteAccount() async {
    await _supabase.functions.invoke(AppConstants.functionDeleteAccount);
  }
}
