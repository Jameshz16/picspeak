import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import '../features/camera/presentation/camera_screen.dart';
import '../features/object_recognition/presentation/result_screen.dart';
import '../features/object_recognition/domain/labeled_object.dart';
import '../features/object_recognition/domain/recognized_word.dart';
import '../features/flashcard_review/presentation/flashcard_list_screen.dart';
import '../features/flashcard_review/presentation/flashcard_review_screen.dart';
import '../features/word_history/presentation/history_screen.dart';
import '../features/app_settings/presentation/settings_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/data/onboarding_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final hasSeen = await onboardingRepo.hasSeenOnboarding();
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      if (!hasSeen && !isOnboardingRoute) {
        return '/onboarding';
      }
      if (hasSeen && isOnboardingRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const CameraScreen(),
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
        ],
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final word = extra['word'] as RecognizedWord?;
          final allLabels = (extra['allLabels'] as List<dynamic>?)
              ?.whereType<LabeledObject>()
              .toList();
          if (word == null) {
            return const Scaffold(
              body: Center(child: Text('No word data provided.')),
            );
          }
          return ResultScreen(
            word: word,
            allLabels: allLabels ?? [],
          );
        },
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const FlashcardReviewScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});
