import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_repository.dart';
import '../domain/user_profile.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  UserProfile? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserProfile.fromFirebase(user);
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserProfile.fromFirebase(user);
    });
  }

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserProfile.fromFirebase(result.user!);
  }

  @override
  Future<UserProfile> registerWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (displayName != null && displayName.isNotEmpty) {
      await result.user!.updateDisplayName(displayName);
    }

    return UserProfile.fromFirebase(result.user!);
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in was cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    return UserProfile.fromFirebase(result.user!);
  }

  @override
  Future<void> signOut() async {
    // Sign out remotely FIRST. Local uid-scoped data is only cleared once
    // the remote sign-out succeeded, so a failed sign-out (offline, etc.)
    // never destroys local data while the session is still active.
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    await clearLocalData();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.delete();
  }

  @override
  Future<void> clearLocalData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.contains(uid)) {
        await prefs.remove(key);
      }
    }
  }

  @override
  Future<void> deleteAccountAndClearData() async {
    // Delete the Firebase account FIRST. Local uid-scoped data is only
    // cleared once the remote deletion succeeded, so a failed delete
    // (stale credentials, offline) never destroys local data.
    await deleteAccount();
    try {
      await clearLocalData();
    } catch (_) {
      // Local data cleanup failed, but the remote account is already
      // deleted. The caller must still navigate to login.
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
