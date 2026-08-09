import 'user_profile.dart';

/// Auth repository contract.
///
/// [clearLocalData] removes all uid-scoped SharedPreferences keys for the
/// current user. Call this on sign-out to ensure the next user does not see
/// the previous user's locally persisted data.
///
/// [deleteAccountAndClearData] does the same plus deletes the Firebase account.
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

  /// Clear all locally persisted data for the current user.
  Future<void> clearLocalData();

  /// Delete the Firebase account AND clear all local data.
  Future<void> deleteAccountAndClearData();
}
