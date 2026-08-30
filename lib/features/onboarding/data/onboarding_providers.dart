import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  throw UnimplementedError(
    'Override this provider with an initialized OnboardingRepository',
  );
});

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.hasSeenOnboarding();
});
