import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../premium/data/premium_providers.dart';
import '../data/auth_providers.dart';
import 'login_screen.dart';

/// Wraps the app and shows login if not authenticated,
/// or the child widget if authenticated.
///
/// Also syncs Firebase Auth state with RevenueCat:
///   - On login → identifies user in RevenueCat
///   - On logout → logs out from RevenueCat
class AuthGate extends ConsumerStatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // Sync RevenueCat with Firebase Auth state
        final userId = user?.uid;
        if (userId != null && userId != _lastUserId) {
          // User logged in or switched — identify in RevenueCat
          _lastUserId = userId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(revenueCatRepositoryProvider).identify(userId);
            // Refresh premium status after identification
            ref.invalidate(premiumStatusProvider);
            // Refresh scan-limit counters so one account's limits never
            // leak into another account's session.
            ref.invalidate(remainingScansProvider);
            ref.invalidate(todayScanCountProvider);
          });
        } else if (userId == null && _lastUserId != null) {
          // User logged out — log out from RevenueCat
          _lastUserId = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(revenueCatRepositoryProvider).logout();
            ref.invalidate(premiumStatusProvider);
            ref.invalidate(remainingScansProvider);
            ref.invalidate(todayScanCountProvider);
          });
        }

        if (user == null) {
          return const LoginScreen();
        }
        return widget.child;
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
            ],
          ),
        ),
      ),
    );
  }
}
