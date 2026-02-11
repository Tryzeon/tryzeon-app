import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<void> signInWithGoogleNative() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const UnauthenticatedException();
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      // accessToken is not required for Supabase authentication with Google
    );
  }

  Future<void> signInWithFacebookNative() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
    );

    if (result.status != LoginStatus.success) {
      throw const UnauthenticatedException();
    }

    final accessToken = result.accessToken!.tokenString;

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.facebook,
      idToken: accessToken,
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
