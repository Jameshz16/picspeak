import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.delete();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
