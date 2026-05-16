import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'features/app_settings/data/settings_repository_impl.dart';
import 'features/app_settings/data/settings_providers.dart';
import 'features/onboarding/data/onboarding_repository_impl.dart';
import 'features/onboarding/data/onboarding_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final onboardingRepo = OnboardingRepositoryImpl(prefs);
  final settingsRepo = SettingsRepositoryImpl(prefs);

  runApp(
    ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
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
