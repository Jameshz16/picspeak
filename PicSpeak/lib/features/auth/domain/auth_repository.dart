import 'user_profile.dart';

abstract class AuthRepository {
  /// Current user (null if not logged in).
  UserProfile? get currentUser;

  /// Stream of auth state changes.
  Stream<UserProfile?> get authStateChanges;

  /// Sign in with email and password.
  Future<UserProfile> signInWithEmail(String email, String password);

  /// Register with email and password.
  Future<UserProfile> registerWithEmail(String email, String password, {String? displayName});

  /// Sign in with Google.
  Future<UserProfile> signInWithGoogle();

  /// Sign out.
  Future<void> signOut();

  /// Delete account.
  Future<void> deleteAccount();

  /// Send password reset email.
  Future<void> sendPasswordReset(String email);
}
