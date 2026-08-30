import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import '../domain/user_profile.dart';
import 'firebase_auth_repository.dart';

/// Auth repository provider — use Firebase in production.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Current user stream.
final authStateProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Current user (synchronous, for non-stream contexts).
final currentUserProvider = Provider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

/// Whether user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
