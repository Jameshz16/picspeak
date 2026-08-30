# Design: Notifications

## Technical Approach

New `lib/features/notifications/` following existing Clean Architecture + Riverpod pattern. `NotificationScheduler` wraps `flutter_local_notifications` with `zonedSchedule`; `UsageTimeTracker` derives modal review hour from app-open timestamps. Integrates `getDueCount()` and streak keys for content. FCM token listener for future campaigns. Settings persist via existing `AppSettings` JSON-in-SharedPreferences.

## Architecture Decisions

| Decision | Choice | Alternatives | Rationale |
|----------|--------|-------------|-----------|
| Background scheduling | `flutter_local_notifications` `zonedSchedule` | `workmanager` package | No background fetch needed for local-only reminders; `zonedSchedule` is simpler, fewer platform quirks, already handles timezone-aware scheduling |
| FCM token storage | Firestore `users/{uid}/fcmToken` | In-memory only, SharedPreferences | Aligns with existing Firestore usage; enables future server-side campaigns without client changes |
| Daily cap tracking | Date-keyed SharedPreferences (`notif_sent_{type}_{YYYY-MM-DD}`) | In-memory counter, SQLite | Lightweight, survives app restart, auto-resets by key design; consistent with existing prefs pattern |
| Schedule time learning | Modal hour from last 30 app-open timestamps | Average time, weighted average | Modal (most frequent hour) is more robust to outliers than average; 30-point window balances recency vs stability |
| Permission request timing | On-demand when user enables notifications in Settings | On first launch, after onboarding | User intent is clear; avoids interrupting first-time flow; matches Android 13+ best practices |
| Deep link handling | `getNotificationAppLaunchDetails()` in `main.dart` + `router.go('/')` | Custom URI scheme, Firebase Dynamic Links | Simplest path — notification taps always go to `/`; no extra routing complexity needed |

## Data Flow

```
App Open
  └─→ UsageTimeTracker.recordOpen()
        └─→ stores timestamp in SharedPreferences

Settings Change (toggle on)
  └─→ NotificationPermissions.request()
        └─→ if granted → NotificationScheduler.rescheduleAll()
              ├─→ reads AppSettings for prefs
              ├─→ reads UsageTimeTracker.getScheduleTime()
              ├─→ checks getDueCount() + streak
              ├─→ applies quiet hours + daily cap
              └─→ zonedSchedule(SRS) + zonedSchedule(streak)

Notification Tap (cold start / background)
  └─→ getNotificationAppLaunchDetails()
        └─→ router.go('/')  (home screen)
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/features/notifications/domain/notification_settings.dart` | Create | Data class: enabled flags, schedule prefs |
| `lib/features/notifications/domain/notification_repository.dart` | Create | Abstract interface for scheduling/permissions |
| `lib/features/notifications/data/notification_repository_impl.dart` | Create | `flutter_local_notifications` wrapper, `zonedSchedule`, channel setup |
| `lib/features/notifications/data/usage_time_tracker.dart` | Create | Records opens, computes modal hour from SharedPreferences |
| `lib/features/notifications/data/notification_permissions.dart` | Create | Android 13+ `POST_NOTIFICATIONS` + iOS permission flow via `permission_handler` |
| `lib/features/notifications/data/fcm_token_handler.dart` | Create | `firebase_messaging` token listener, writes to Firestore `users/{uid}/fcmToken` |
| `lib/features/notifications/data/notification_providers.dart` | Create | Riverpod providers for all notification dependencies |
| `lib/features/notifications/presentation/notification_settings_section.dart` | Create | Settings UI: master toggle, per-type toggles, time picker |
| `lib/features/app_settings/domain/app_settings.dart` | Modify | Add `notificationsEnabled`, `srsRemindersEnabled`, `streakRemindersEnabled`, `quietHoursEnabled`, `customScheduleTime` fields |
| `lib/features/app_settings/data/settings_repository_impl.dart` | Modify | Handle new fields in `fromJson`/`toJson` (backward compatible defaults) |
| `lib/features/app_settings/presentation/settings_screen.dart` | Modify | Insert `NotificationSettingsSection` widget |
| `lib/main.dart` | Modify | Init `NotificationScheduler`, `UsageTimeTracker.recordOpen()`, check launch details, FCM init |
| `lib/app/router.dart` | Modify | Add notification deep-link handler (router.go('/') on tap) |
| `pubspec.yaml` | Modify | Add `flutter_local_notifications`, `firebase_messaging`, `timezone` |
| `android/app/src/main/AndroidManifest.xml` | Modify | Add `POST_NOTIFICATIONS` permission, `RECEIVE_BOOT_COMPLETED`, notification broadcast receiver |
| `ios/Runner/Info.plist` | Modify | Add `NSUserNotificationsUsageDescription` |

## Interfaces / Contracts

```dart
// domain/notification_repository.dart
abstract class NotificationRepository {
  Future<bool> requestPermission();
  Future<bool> getPermissionStatus();
  Future<void> scheduleSrsReminder(int dueCount, DateTime scheduledTime);
  Future<void> scheduleStreakReminder(int streakDays, DateTime scheduledTime);
  Future<void> cancelAll();
  Future<void> cancelByType(String type);
}
```

```dart
// domain/notification_settings.dart (fields added to AppSettings)
// New fields in AppSettings:
final bool notificationsEnabled;      // default: false
final bool srsRemindersEnabled;       // default: true
final bool streakRemindersEnabled;    // default: true
final bool quietHoursEnabled;         // default: true
final TimeOfDay? customScheduleTime;  // default: null (use learned)
```

```dart
// data/usage_time_tracker.dart
class UsageTimeTracker {
  Future<void> recordOpen();                    // stores DateTime.now() in prefs
  Future<TimeOfDay> getScheduleTime();          // modal hour - 30min, fallback 16:00
}
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | `UsageTimeTracker` modal hour | Inject fake SharedPreferences with known timestamps |
| Unit | Quiet hours + daily cap | Pure functions, date-keyed prefs mock |
| Unit | `AppSettings.fromJson` compat | Old JSON without new fields → defaults |
| Integration | Scheduler + permission flow | Mock `flutter_local_notifications` + `permission_handler` |
| E2E | Notification tap → home | Mock launch details + router verification |

## Migration / Rollout

No migration required. New `AppSettings` fields use backward-compatible defaults — existing installs deserialize with `notificationsEnabled: false`. Notifications are opt-in. FCM token listener is passive.

## Open Questions

- [ ] FCM token: store in Firestore `users/{uid}/fcmToken` or `users/{uid}/messagingTokens/{token}`? Single-field is simpler but array supports multi-device. Recommend single-field for now (one device per child account).
- [ ] Should `timezone` package initialization happen in `main.dart` or inside `NotificationScheduler.init()`? Recommend inside scheduler to keep init self-contained.
