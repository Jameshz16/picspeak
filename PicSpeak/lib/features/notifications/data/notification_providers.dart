import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_settings/data/settings_providers.dart';
import '../../flashcard_review/data/flashcard_providers.dart';
import '../../stats/data/stats_repository.dart';
import '../domain/notification_repository.dart';
import 'fcm_token_handler.dart';
import 'notification_permissions.dart';
import 'notification_repository_impl.dart';
import 'usage_time_tracker.dart';

final notificationPermissionsProvider = Provider<NotificationPermissions>((ref) {
  return NotificationPermissions();
});

final usageTimeTrackerProvider = FutureProvider<UsageTimeTracker>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return UsageTimeTracker(prefs);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  throw UnimplementedError(
    'Override this provider with an initialized NotificationRepository',
  );
});

final fcmTokenHandlerProvider = Provider.autoDispose<FcmTokenHandler>((ref) {
  final messaging = FirebaseMessaging.instance;
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final handler = FcmTokenHandler(
    messaging: messaging,
    auth: auth,
    firestore: firestore,
  );

  ref.onDispose(() {
    handler.dispose();
  });

  return handler;
});
