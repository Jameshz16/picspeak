import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/camera/presentation/camera_screen.dart';
import '../../features/object_recognition/presentation/result_screen.dart';
import '../../features/flashcard_review/presentation/flashcard_list_screen.dart';
import '../../features/flashcard_review/presentation/flashcard_review_screen.dart';
import '../../features/word_history/presentation/history_screen.dart';
import '../../features/app_settings/presentation/settings_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/data/onboarding_providers.dart';

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
      GoRoute(
        path: '/',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/result/:wordId',
        builder: (context, state) {
          final wordId = state.pathParameters['wordId']!;
          return ResultScreen(wordId: wordId);
        },
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FlashcardListScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const FlashcardReviewScreen(),
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
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});
