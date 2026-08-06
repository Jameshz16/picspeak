import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'features/app_settings/data/settings_providers.dart';
import 'features/app_settings/data/settings_repository_impl.dart';
import 'features/flashcard_review/data/flashcard_providers.dart';
import 'features/flashcard_review/data/flashcard_repository_impl.dart';
import 'features/notifications/data/fcm_token_handler.dart';
import 'features/notifications/data/notification_permissions.dart';
import 'features/notifications/data/notification_providers.dart';
import 'features/notifications/data/notification_repository_impl.dart';
import 'features/notifications/data/usage_time_tracker.dart';
import 'features/onboarding/data/onboarding_repository_impl.dart';
import 'features/onboarding/data/onboarding_providers.dart';
import 'features/stats/data/stats_repository.dart';
import 'features/word_history/data/history_providers.dart';
import 'features/word_history/data/history_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();

  // Repositories needed early
  final onboardingRepo = OnboardingRepositoryImpl(prefs);
  final settingsRepo = SettingsRepositoryImpl(prefs);
  final flashcardRepo = FlashcardRepositoryImpl(prefs);
  final historyRepo = HistoryRepositoryImpl(prefs);
  final statsRepo = StatsRepository(prefs);

  // Notification infrastructure (non-fatal on failure)
  bool launchedFromNotification = false;
  final notificationPlugin = FlutterLocalNotificationsPlugin();
  final usageTimeTracker = UsageTimeTracker(prefs);
  final permissions = NotificationPermissions();

  final notificationRepo = NotificationRepositoryImpl(
    notificationsPlugin: notificationPlugin,
    prefs: prefs,
    usageTimeTracker: usageTimeTracker,
    permissions: permissions,
    flashcardRepository: flashcardRepo,
    statsRepository: statsRepo,
  );

  // Record app open for smart scheduling (independent of notification state).
  // Guarded separately so a prefs failure never becomes an unhandled async error.
  try {
    await usageTimeTracker.recordOpen();
  } catch (e) {
    debugPrint('Usage time tracker recordOpen failed: $e');
  }

  // Notification infrastructure init (non-fatal on failure)
  try {
    await NotificationRepositoryImpl.initialize();
    await notificationRepo.init();

    // Check if app was launched from a notification tap
    final launchDetails =
        await notificationPlugin.getNotificationAppLaunchDetails();
    launchedFromNotification =
        launchDetails?.didNotificationLaunchApp ?? false;
  } catch (e) {
    // If notification init fails, continue without notifications.
    debugPrint('Notification init failed: $e');
  }

  // Initialize FCM token handler (silent if no user logged in).
  // Attach catchError so async errors from getToken() never escape as
  // unhandled Futures — making the "non-fatal FCM init" guarantee true.
  final fcmHandler = FcmTokenHandler(
    messaging: FirebaseMessaging.instance,
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
  fcmHandler.init().catchError((e) {
    debugPrint('FCM token handler async error: $e');
  });

  runApp(
    ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        flashcardRepositoryProvider.overrideWithValue(flashcardRepo),
        historyRepositoryProvider.overrideWithValue(historyRepo),
        notificationRepositoryProvider.overrideWithValue(notificationRepo),
      ],
      child: PicSpeakApp(launchedFromNotification: launchedFromNotification),
    ),
  );
}

class PicSpeakApp extends ConsumerWidget {
  final bool launchedFromNotification;

  const PicSpeakApp({super.key, this.launchedFromNotification = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // If launched from a notification tap, navigate to home
    if (launchedFromNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go('/');
      });
    }

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
