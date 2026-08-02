import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'features/app_settings/data/settings_providers.dart';
import 'features/app_settings/data/settings_repository_impl.dart';
import 'features/flashcard_review/data/flashcard_providers.dart';
import 'features/flashcard_review/data/flashcard_repository_impl.dart';
import 'features/onboarding/data/onboarding_repository_impl.dart';
import 'features/onboarding/data/onboarding_providers.dart';
import 'features/word_history/data/history_providers.dart';
import 'features/word_history/data/history_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();

  final onboardingRepo = OnboardingRepositoryImpl(prefs);
  final settingsRepo = SettingsRepositoryImpl(prefs);
  final flashcardRepo = FlashcardRepositoryImpl(prefs);
  final historyRepo = HistoryRepositoryImpl(prefs);

  runApp(
    ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        flashcardRepositoryProvider.overrideWithValue(flashcardRepo),
        historyRepositoryProvider.overrideWithValue(historyRepo),
      ],
      child: const PicSpeakApp(),
    ),
  );
}

class PicSpeakApp extends ConsumerWidget {
  const PicSpeakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'PicSpeak',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
