# Tasks: Notifications

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~850-900 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 → PR 3 → PR 4 |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Platform config + domain models + settings delta | PR 1 | Base: `feature/notifications`. Deps, AndroidManifest, Info.plist, domain interfaces, AppSettings fields. ~200 lines. |
| 2 | Data layer: scheduler, tracker, permissions, FCM, providers | PR 2 | Base: PR 1 branch. Core implementations + Riverpod providers. ~300 lines. |
| 3 | UI + wiring: settings section, main.dart init, deep-link handler | PR 3 | Base: PR 2 branch. Presentation + integration. ~180 lines. |
| 4 | Tests: unit + integration | PR 4 | Base: PR 3 branch. All test files. ~170 lines. |

---

## Phase 1: Platform Config + Domain Foundation (PR 1)

- [x] 1.1 `pubspec.yaml` — add `flutter_local_notifications`, `firebase_messaging`, `timezone` deps
- [x] 1.2 `android/app/src/main/AndroidManifest.xml` — add `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, notification broadcast receiver
- [x] 1.3 `ios/Runner/Info.plist` — add `NSUserNotificationsUsageDescription`
- [x] 1.4 Create `lib/features/notifications/domain/notification_repository.dart` — abstract class with `requestPermission()`, `getPermissionStatus()`, `scheduleSrsReminder()`, `scheduleStreakReminder()`, `cancelAll()`, `cancelByType()`
- [x] 1.5 Create `lib/features/notifications/domain/notification_settings.dart` — data class for notification-specific settings (if separate from AppSettings; otherwise skip if fields go directly into AppSettings)
- [x] 1.6 Modify `lib/features/app_settings/domain/app_settings.dart` — add `notificationsEnabled` (default false), `srsRemindersEnabled` (default true), `streakRemindersEnabled` (default true), `quietHoursEnabled` (default true), `customScheduleTime` (nullable TimeOfDay). Update `copyWith`, `toJson`, `fromJson` with backward-compatible defaults.
- [x] 1.7 Modify `lib/features/app_settings/data/settings_repository_impl.dart` — verify `fromJson` handles missing new fields gracefully (existing code delegates to `AppSettings.fromJson` — confirm no breakage)

**Verification**: `flutter analyze` passes; old settings JSON round-trips without crash; new fields serialize/deserialize correctly.

---

## Phase 2: Data Layer — Scheduler, Tracker, Permissions, FCM (PR 2)

- [x] 2.1 Create `lib/features/notifications/data/usage_time_tracker.dart` — `recordOpen()` stores timestamp in SharedPreferences; `getScheduleTime()` computes modal hour from last 30 opens, subtracts 30min, falls back to 16:00 if <5 opens
- [x] 2.2 Create `lib/features/notifications/data/notification_permissions.dart` — Android 13+ `POST_NOTIFICATIONS` request via `permission_handler`; iOS system dialog; graceful denial handling
- [x] 2.3 Create `lib/features/notifications/data/notification_repository_impl.dart` — wraps `flutter_local_notifications`; init with Android channel + iOS settings; `zonedSchedule` for SRS/streak; quiet hours clamp (21:00–08:00 → 08:00); daily cap via date-keyed SharedPreferences (`notif_sent_{type}_{YYYY-MM-DD}`); `cancelAll()`/`cancelByType()`
- [x] 2.4 Create `lib/features/notifications/data/fcm_token_handler.dart` — `firebase_messaging` token listener; writes to Firestore `users/{uid}/fcmToken`; no campaign sending
- [x] 2.5 Create `lib/features/notifications/data/notification_providers.dart` — Riverpod providers for `NotificationRepository`, `UsageTimeTracker`, `FcmTokenHandler`, `NotificationPermissions`

**Verification**: Unit tests for `UsageTimeTracker` modal-hour logic; unit test for quiet-hours clamp; mock-based test for `NotificationRepositoryImpl.scheduleSrsReminder` calling `zonedSchedule` with correct args.

---

## Phase 3: UI + Wiring (PR 3)

- [ ] 3.1 Create `lib/features/notifications/presentation/notification_settings_section.dart` — master toggle (SwitchListTile), per-type toggles (SRS, streak), optional time picker; calls `NotificationRepository.cancelAll()` on master off; calls `rescheduleAll()` on toggle on
- [ ] 3.2 Modify `lib/features/app_settings/presentation/settings_screen.dart` — insert `NotificationSettingsSection` widget after Theme section, before Learning section
- [ ] 3.3 Modify `lib/main.dart` — init `NotificationScheduler` (timezone + plugin), call `UsageTimeTracker.recordOpen()`, check `getNotificationAppLaunchDetails()` for cold-start tap, init FCM token handler
- [ ] 3.4 Modify `lib/app/router.dart` — add notification tap deep-link: if launch from notification, `router.go('/')`

**Verification**: Manual test: toggle notifications on → permission dialog appears; toggle off → scheduled notifications cancelled; cold-start tap from notification lands on home.

---

## Phase 4: Tests (PR 4)

- [ ] 4.1 Unit test `UsageTimeTracker` — <5 opens → fallback 16:00; ≥5 opens → modal hour - 30min; edge case: all opens same hour
- [ ] 4.2 Unit test quiet hours — candidate 22:00 → deferred to 08:00; candidate 15:00 → unchanged
- [ ] 4.3 Unit test daily cap — second schedule same day same type → no duplicate; next day → allowed
- [ ] 4.4 Unit test `AppSettings.fromJson` backward compat — old JSON without new fields → defaults (notificationsEnabled=false, others=true)
- [ ] 4.5 Integration test scheduler + permission — mock `flutter_local_notifications` + `permission_handler`; grant → schedules fire; deny → no crash, no schedule
- [ ] 4.6 Integration test notification tap → home — mock `getNotificationAppLaunchDetails()` with payload → verify router navigates to `/`

**Verification**: `flutter test` all green; coverage for notification domain ≥80%.
