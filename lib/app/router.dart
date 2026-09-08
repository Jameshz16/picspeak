import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import 'sb_animations.dart';
import '../features/gallery/presentation/gallery_screen.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/data/auth_providers.dart';
import '../features/camera/presentation/camera_screen.dart';
import '../features/object_recognition/presentation/result_screen.dart';
import '../features/object_recognition/domain/labeled_object.dart';
import '../features/object_recognition/domain/recognized_word.dart';
import '../features/flashcard_review/presentation/flashcard_list_screen.dart';
import '../features/flashcard_review/presentation/flashcard_review_screen.dart';
import '../features/flashcard_review/presentation/review_today_screen.dart';
import '../features/categories/presentation/category_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/word_history/presentation/history_screen.dart';
import '../features/app_settings/presentation/settings_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/data/onboarding_providers.dart';
import '../features/premium/presentation/paywall_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  // Use synchronous FirebaseAuth.currentUser as fallback while
  // the stream initializes, preventing a login-screen flash for
  // returning users whose auth token is still loading.
  final isLoggedIn = authState.isLoading
      ? FirebaseAuth.instance.currentUser != null
      : authState.valueOrNull != null;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final hasSeen = await onboardingRepo.hasSeenOnboarding();
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Onboarding redirect
      if (!hasSeen && !isOnboardingRoute) {
        return '/onboarding';
      }
      if (hasSeen && isOnboardingRoute) {
        return '/';
      }

      // Auth redirect
      if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            sbRouteTransition(const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            sbRouteTransition(const RegisterScreen()),
      ),

      // Main app shell
      ShellRoute(
        builder: (context, state, child) => AuthGate(
          child: AppShell(child: child),
        ),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const CameraScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoryScreen(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FlashcardListScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/gallery',
            builder: (context, state) => const GalleryScreen(),
          ),
        ],
      ),

      // Standalone routes (outside shell)
      GoRoute(
        path: '/result',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final word = extra['word'] as RecognizedWord?;
          final allLabels = (extra['allLabels'] as List<dynamic>?)
              ?.whereType<LabeledObject>()
              .toList();
          final isWordOfDay = extra['isWordOfDay'] as bool? ?? false;
          if (word == null) {
            return sbRouteTransition(const Scaffold(
                body: Center(child: Text('No word data provided.')),
              ),
            );
          }
          return sbRouteTransition(ResultScreen(
              word: word,
              allLabels: allLabels ?? [],
              isWordOfDay: isWordOfDay,
            ),
          );
        },
      ),
      GoRoute(
        path: '/review',
        pageBuilder: (context, state) {
          final indexStr = state.uri.queryParameters['index'];
          final initialIndex = int.tryParse(indexStr ?? '') ?? 0;
          return sbRouteTransition(FlashcardReviewScreen(initialIndex: initialIndex),
          );
        },
      ),
      GoRoute(
        path: '/review-today',
        pageBuilder: (context, state) => sbRouteTransition(const ReviewTodayScreen(),
        ),
      ),
      GoRoute(
        path: '/category/:id',
        pageBuilder: (context, state) {
          final categoryId = state.pathParameters['id']!;
          return sbRouteTransition(CategoryWordsScreen(categoryId: categoryId),
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => sbRouteTransition(const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) => sbRouteTransition(const PaywallScreen(),
        ),
      ),
    ],
  );
});
